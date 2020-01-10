# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Add department in 852$b              ################################"
puts "##########################   Expected collection size: 1.800    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

records = Source.where(lib_siglum: "PL-Wbfc") + Holding.where(lib_siglum: "PL-Wbfc")
maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("852") do |tag|
    next if tag.fetch_first_by_tag("b")
    tag.add(MarcNode.new(Source, "b", "Biblioteka Narodowego Instytutu Fryderyka Chopina", nil))
    tag.sort_alphabetically
    modified = true
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: Record ##{record.class.to_s} added $b Biblioteka ...") if modified
    record.save
  end
}

maintenance.execute process
