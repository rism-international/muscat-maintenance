# encoding: UTF-8
puts "##################################################################################################"
puts "#################      Add and change 856$x with Sources and Holdings         ####################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Holding.where('marc_source like ?', "%resolving.de/%") + Source.where('marc_source like ?', "%resolving.de/%") 

maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("856") do |tag|
    tag_u = tag.fetch_first_by_tag("u") 
    tag_x = tag.fetch_first_by_tag("x") 
    tag_z = tag.fetch_first_by_tag("z")

    if tag_u.content.include?("nbn-resolving.de") || tag_u.content.include?("mdz-nbn-resolving.de") 
      if tag_x and tag_x.content == "Digitized"
        if !tag_z
          tag.add(MarcNode.new(record.class, "z", "Digitalisat", nil))
          tag.sort_alphabetically
          modified = true
        elsif tag_z.blank?
          tag_z.content = "Digitalisat"
          modified = true
        else
          next
        end
      end
    end

    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id} '$z' created 'Digitized'") if modified
  
  end

  if modified
    record.save
  end
}

maintenance.execute process
