# encoding: UTF-8
puts "##################################################################################################"
puts "##########################  Add digitalization links of A-SPD etc. ###############################"
puts "############################   Expected collection size: 923  ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml

sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  url = yaml[record.id]
  object = record.holdings.empty? ? record : record.holdings.where(:lib_siglum => "D-NATk").take  
  if !object
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} has no holding from 'D-NATk'")
  else
    marc = object.marc
    new_856 = MarcNode.new(Source, "856", "", "4#")
    ip = marc.get_insert_position("856")
    new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
    new_856.add(MarcNode.new(Source, "x", "IIIF", nil))
    new_856.add(MarcNode.new(Source, "z", "[digitized version]", nil))
    marc.root.children.insert(ip, new_856)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{url}'")
    modified = true
    object.save if modified
  end
}

maintenance.execute process
