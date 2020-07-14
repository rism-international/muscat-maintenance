# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Remove 852 from some Sistina records              #######################"
puts "##########################   Expected collection size: ca.694   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


sources = Folder.find(428).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|

  modified = false
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.each_by_tag("852") do |e|
    e.destroy_yourself
    modified = true
  end
  
  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    record.save! rescue next
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} removed 852")
  end
  
}

maintenance.execute process
