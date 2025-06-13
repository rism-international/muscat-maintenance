# encoding: UTF-8
puts "##################################################################################################"
puts "#################      Add and change 856$x with Sources and Holdings         ####################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Holding.where('marc_source like ?', "%http://nbn-resolving.de/urn/resolver.pl?urn%") + Source.where('marc_source like ?', "%http://nbn-resolving.de/urn/resolver.pl?urn%")
  
maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("856") do |tag|
    tag_u = tag.fetch_first_by_tag("u") 
    if tag_u && tag_u.content && tag_u.content.starts_with?("http://nbn-resolving.de/urn/resolver.pl?urn")
      tag_u.content = tag_u.content.gsub("http://nbn-resolving.de/urn/resolver.pl?urn=", "https://mdz-nbn-resolving.de/")
      modified = true
    end
    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id} modified 856$u") if modified
  end

  if modified
    record.save
  end
}

maintenance.execute process
