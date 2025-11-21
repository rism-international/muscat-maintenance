# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Change fields with folder items from ICCU         #######################"
puts "##########################   Expected collection size: ca.50    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


sources = Folder.find(1625).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  marc = record.marc
  unless marc.has_tag?("980")
    df = MarcNode.new(Source, "980", "", "##")
    ip = marc.get_insert_position("980")
    df.add(MarcNode.new(Source, "a", "RISM", nil))
    df.add(MarcNode.new(Source, "c", "not_examined", nil))
    marc.root.children.insert(ip, df)
  else
    tag = marc.first_occurance("980")
    subtag = tag.fetch_first_by_tag("c")
    if subtag
      subtag.content = "not_examined"
    else
      tag.add(MarcNode.new(Source, "c", "not_examined", nil))
    end
  end

  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 980$c not_examined")
  record.save
}

maintenance.execute process
