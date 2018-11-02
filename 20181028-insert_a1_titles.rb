# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Insert a1 titles         ##################################"
puts "#######################   Expected collection size: c.22.300     #################################"
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

      if record.versions.size > 0
        logger.warn("#{hostname}: Print #{record.id} has updated data!")
        next
      end
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
        #### TITLE ###
        title = hash["240a"][0]
        other_titles = hash["240a"][1..-1]
        new_marc.each_by_tag("240") do |tag|
          tag.destroy_yourself
          new_240 = MarcNode.new(Source, "240", "", "##")
          ip = new_marc.get_insert_position("240")
          new_240.add(MarcNode.new(Source, "a", "#{title}", nil))
          new_marc.root.children.insert(ip, new_240)
          modified = true
        end
        if other_titles && !new_marc.has_tag?("730")
          other_titles.each do |ot|
            new_730 = MarcNode.new(Source, "730", "", "##")
            ip = new_marc.get_insert_position("730")
            new_730.add(MarcNode.new(Source, "a", "#{ot}", nil))
            new_marc.root.children.insert(ip, new_730)
            modified = true
          end
        end

        ### OPUS ###
        opus = hash["383b"]
        if opus && !new_marc.has_tag?("383")
          new_383 = MarcNode.new(Source, "383", "", "##")
          ip = new_marc.get_insert_position("383")
          new_383.add(MarcNode.new(Source, "b", "#{opus}", nil))
          new_marc.root.children.insert(ip, new_383)
          modified = true
        end

        ### GENRE ###
        genres = hash["650a"]
        existing_genres = new_marc.all_values_for_tags_with_subtag("650", "a")
        if genres && existing_genres.empty?
          genres.each do |genre|
            new_650 = MarcNode.new(Source, "650", "", "##")
            ip = new_marc.get_insert_position("650")
            new_650.add(MarcNode.new(Source, "a", "#{genre}", nil))
            new_marc.root.children.insert(ip, new_650)
            modified = true
          end
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

