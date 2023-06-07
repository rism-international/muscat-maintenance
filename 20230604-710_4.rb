# encoding: UTF-8
puts "##################################################################################################"
puts "#################  Repair 710 function 710$4 with Sources and Holdings for Moravian  #############"
puts "############################   Expected size: ca. 2.000       ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Holding.where('marc_source like ?', "%Moravian Music%") + Source.where('marc_source like ?', "%Moravian Music%") 
maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("710") do |tag|
    tag_a = tag.fetch_first_by_tag("a") 
    tag_4 = tag.fetch_first_by_tag("4") 

    if !tag_4
      if tag_a.content && tag_a.content.include?("Moravian Music")
        tag.add(MarcNode.new(record.class, "4", "oth", nil))
        modified = true
      end
    end
  
  end

  record_id = record.class == Source ? record.id : "#{record.source_id}:#{record.id}"

  if modified
    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record_id} '$4' added 'oth'") if modified
#    record.save
  end
}

maintenance.execute process
