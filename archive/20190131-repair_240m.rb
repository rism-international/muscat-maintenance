# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Repair 240m with A/I     ##################################"
puts "#######################   Expected collection size: c.2000     ###################################"
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

      #if record.versions.size > 1
      #  logger.warn("#{hostname}: Print #{record.id} has updated data!")
      #  next
      #end
      archived_record = record.versions.first.reify rescue next
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
        #### repair 240m ###
        archived_marc = MarcSource.new(archived_record.marc_source)
        archived_marc.load_source(false)
        archived_240m = archived_marc.first_occurance("240", "m")
        existent_240m = new_marc.first_occurance("240", "m")
        if archived_240m && !existent_240m
          new_marc.each_by_tag("240") do |tag|
            tag.add(MarcNode.new(Source, "m", "#{archived_240m.content}", nil))
            tag.sort_alphabetically
            modified = true
          end
        else
          next
        end
      end
      
      if modified 
        import_marc = MarcSource.new(new_marc.to_marc)
        import_marc.load_source(false)
        import_marc.import
        record.marc = import_marc
        record.record_type = record_type
        record.save!
        logger.info("#{hostname}: Print #{record.id} inserted 240m with #{archived_240m.content}")
      end

    end
  end
  bar.increment!
end

