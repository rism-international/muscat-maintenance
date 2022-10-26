# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################           ISSUE: Add 0359               #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Folder.find(896).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  new_035 = MarcNode.new(Source, "035", "", "##")
  ip = record.marc.get_insert_position("035")
  new_035.add(MarcNode.new(Source, "a", "450331000", nil))
  record.marc.root.children.insert(ip, new_035)
  record.save
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 035 with content '450331000'")



}
maintenance.execute process
