# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Destroy places by folder                          #######################"
puts "##########################   Expected collection size: ca.3.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

places = Folder.find(753).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(places)

process = lambda { |record|
  messages = []
  next unless record
  has_link = false

  ref = record.referring_dependencies.select{|k,v| v > 0}
  ref.keys.each do |key|
    if key == "referring_sources" || key == "referring_people"
      has_link = true
      next
    end
    assocs = record.send(key)
    assocs.each do | foreign_record |
      modified = false
      foreign_record.marc.all_tags.each do |tag|
        if tag.foreign_object && tag.foreign_object.id == record.id
          messages <<  "#{maintenance.host}: FOREIGN #{key} ##{foreign_record.id} '#{foreign_record.name}' TAG with #{record.id} dropped"
          tag.destroy_yourself
          modified = true
        end
      foreign_record.save if modified
      end
    end
  end
  next if has_link
  
  messages <<  "#{maintenance.host}: Place ##{record.id} '#{record.name}' destroyed"

  record.destroy
  messages.each do |message|
    maintenance.logger.info(message)
  end
  
}

maintenance.execute process


