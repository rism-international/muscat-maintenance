# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Change private collections for institutions       #######################"
puts "##########################   Expected collection size: ca.600   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


institutions = Folder.find(1594).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(institutions)

process = lambda { |record|
  marc = record.marc
  df = MarcNode.new(Source, "368", "", "##")
  ip = marc.get_insert_position("368")
  df.add(MarcNode.new(Source, "a", "Private collection", nil))
  marc.root.children.insert(ip, df)
  maintenance.logger.info("#{maintenance.host}: Institution ##{record.id} added 368$a private collection_examined")
  record.save
}

maintenance.execute process
