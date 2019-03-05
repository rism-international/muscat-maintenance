# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Insert a1 enthalten_in   ##################################"
puts "#######################   Expected collection size: c.4.700      #################################"
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
        ### ENTHALTEN IN ###
        enthalten_in = hash["730a"]
        new_730 = MarcNode.new(Source, "730", "", "##")
        ip = new_marc.get_insert_position("730")
        new_730.add(MarcNode.new(Source, "a", "#{enthalten_in.strip}", nil))
        new_marc.root.children.insert(ip, new_730)
        modified = true
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
