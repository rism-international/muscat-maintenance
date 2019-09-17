# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Change template with folder items from slub       #######################"
puts "##########################   Expected collection size: 7        ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


sources = Folder.find(311).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.change_template_to(1)
  #record.update(record_type: 11)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} switched to collection template")
}

maintenance.execute process
