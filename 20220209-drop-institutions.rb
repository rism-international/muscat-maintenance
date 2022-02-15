# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Destroy institutions by folder                    #######################"
puts "##########################   Expected collection size: ca.4.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


institutions = Folder.find(751).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(institutions)

process = lambda { |record|
  messages = []
  next unless record
  has_link = false

  record_modified = false
  ref = record.referring_dependencies.select{|k,v| v > 0}
  ref.keys.each do |key|
    if key == "referring_sources"
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
  record.marc.all_tags.each do |tag|
    if tag.foreign_object
      tag.destroy_yourself
      record_modified = true
    end
  end
  record.save if record_modified
  messages <<  "#{maintenance.host}: Institution ##{record.id} '#{record.name}' destroyed"

  record.destroy
  messages.each do |message|
    maintenance.logger.info(message)
  end
  
}

maintenance.execute process
