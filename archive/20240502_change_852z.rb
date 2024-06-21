# encoding: UTF-8
puts "##################################################################################################"
puts "#########################      Repair multiple master nodes                   ####################"
puts "################################   Expected size: ca. 45      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

sources = Folder.find(1211).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)
tags = %w(852)

process = lambda { |record|
  modified = false
  tags.each do | tag_name |
    record.marc.each_by_tag(tag_name) do |tag|
      sf = tag.fetch_first_by_tag("z")
      unless sf
        tag.add(MarcNode.new(Source, "z", "Hofmusikkapelle Wien - Archiv", nil))
        tag.sort_alphabetically
        maintenance.logger.info("#{maintenance.host}: ##{record.id} '#{tag_name}' added 852$z Hofmusikkapelle usf.")
        modified = true
      end
    end
  end
  if modified
    record.save
  end
}

maintenance.execute process
