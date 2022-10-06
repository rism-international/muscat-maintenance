# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################           ISSUE: Add 0359               #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Folder.find(893).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  if record.id.to_s == "450062857"
    next
  end
  new_035 = MarcNode.new(Source, "035", "", "##")
  ip = record.marc.get_insert_position("035")
  new_035.add(MarcNode.new(Source, "a", "45031XXXX", nil))
  record.marc.root.children.insert(ip, new_035)
  record.save
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 035 with content '45031XXXX'")



}
maintenance.execute process
