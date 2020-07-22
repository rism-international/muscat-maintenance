# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Remove 730 from some Sistina records (folder)     #######################"
puts "##########################   Expected collection size: ca.2.700 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


sources = Folder.find(429).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|

  modified = false
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)
  new_marc.root.fetch_all_by_tag("730").each do |e|
    e.destroy_yourself
    modified = true
  end
  
  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    begin
      record.save! 
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} removed 730")
    rescue 
      maintenance.logger.info("#{maintenance.host} ERROR:  Source ##{record.id} removed 730")
    end
  end
  
}

maintenance.execute process
