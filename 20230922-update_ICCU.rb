# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Change fields with folder items from ICCU         #######################"
puts "##########################   Expected collection size: ca.50    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


sources = Folder.find(982).folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  marc = record.marc
  marc.each_by_tag("500") do |tag|
    sf = tag.fetch_first_by_tag("a")
    if sf && sf.content
      if sf.content.starts_with?("Subject heading:")
        sf.destroy_yourself
        if tag.children.empty?
          tag.destroy_yourself
        end
      end
    end
  end
  df = MarcNode.new(Source, "599", "", "##")
  ip = marc.get_insert_position("599")
  df.add(MarcNode.new(Source, "a", "ICCU-Import 2. Paket (September 2023)", nil))
  marc.root.children.insert(ip, df)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} removed 500 and added 599")
  record.save
}

maintenance.execute process
