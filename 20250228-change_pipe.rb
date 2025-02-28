# encoding: UTF-8
puts "##################################################################################################"
puts "################  ISSUE: Change fields with folder items with pipe         #######################"
puts "##########################   Expected collection size: ca.100   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


pubs = Folder.where(name: "Senkrechter Strich in 210").take.folder_items.map{|e| e.item}
maintenance = Muscat::Maintenance.new(pubs)

process = lambda { |record|
  marc = record.marc
  marc.each_by_tag("210") do |tag|
    sf = tag.fetch_first_by_tag("a")
    if sf && sf.content
      if sf.content.include?("|")
        sf.content = sf.content.gsub("|", "-")
      end
    end
  end
  maintenance.logger.info("#{maintenance.host}: Publication ##{record.id} changed | to -")
  record.save
}

maintenance.execute process
