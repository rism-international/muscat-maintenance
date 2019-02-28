# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Insert a1 wv             ##################################"
puts "#######################   Expected collection size: c.7.000      #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
bar = ProgressBar.new(yaml.size)
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
hostname = Socket.gethostname

yaml.each_with_index do |entry, index|
  matched = false
  modified = false
  entry.each do |a1_num,hash|
    sx = Source.solr_search {fulltext a1_num, fields: "035a"}
    if sx.total == 0
      logger.warn("#{hostname}: Print #{a1_num} has no record!")
    end
    sx.results.each do |record|
      record_type = record.record_type

      #  if record.versions.size > 0
      #    logger.warn("#{hostname}: Print #{record.id} has updated data!")
      #    next
      #  end
      new_marc = MarcSource.new(record.marc_source)
      new_marc.load_source(false)

      new_marc.each_by_tag("035") do |tag|
        tag.each_by_tag("a") do |subfield|
          if subfield.content == a1_num
            matched = true
          end
        end
      end

      if matched
        ### WV ###
        ary = hash["690a"]
        if ary && !new_marc.has_tag?("690")
          ary.each do |e|
            wv, no = e
            new_690 = MarcNode.new(Source, "690", "", "##")
            ip = new_marc.get_insert_position("690")
            new_690.add(MarcNode.new(Source, "a", "#{wv}", nil))
            new_690.add(MarcNode.new(Source, "n", "#{no}", nil))
            new_marc.root.children.insert(ip, new_690)
          end
          modified = true
        end
      end
      if modified 
        import_marc = MarcSource.new(new_marc.to_marc)
        import_marc.load_source(false)
        import_marc.import
        record.marc = import_marc
        record.record_type = record_type
        record.save!
        logger.info("#{hostname}: Print #{record.id} updated with migration data")
      end
    end
  end
  bar.increment!
end
