# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE : Change Composer for ICCU   ##################################"
puts "############################   Expected collection size: 9.000  ##################################"
puts "########################    Inherit siglum from collection       #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Folder.find(1102).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  new_composer = record.marc.first_occurance("100")
  children = Source.where(source_id: record.id)
  children.each do |child|
    marc = child.marc
    old_composer = marc.first_occurance("100")
    old_composer.destroy_yourself
    ip = marc.get_insert_position("100")
    marc.root.children.insert(ip, new_composer)
    child.save
    maintenance.logger.info("#{maintenance.host}: #{child.id} composer -> '#{new_composer.to_s}'")
  end
}

maintenance.execute process

