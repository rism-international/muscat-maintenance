# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Remove multiple subtags                   #######################"
puts "############################   Expected collection size: 588    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml

sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  tag = yaml[record.id].to_s
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)
  new_marc.each_by_tag(tag) do |node|
    a_tags = node.fetch_all_by_tag("a")
    if a_tags.size > 1
      modified = true
      a_tags.each do |sf|
        sf.destroy_yourself
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
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} multiple sf #{tag}$a recreated.")
  end
}

maintenance.execute process
