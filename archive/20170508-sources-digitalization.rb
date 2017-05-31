# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Add digitalization links #################################"
puts "############################   Expected collection size: 620  ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

pre_yaml = Muscat::Maintenance.yaml
yaml = {}

pre_yaml.each do |key,value|
  value.each do |k,v|
    yaml[k] = {:url => v, :bib => key}
  end
end
sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  url = yaml[record.id][:url]
  bib = yaml[record.id][:bib]
  object = record.holdings.empty? ? record : record.holdings.where(:lib_siglum => bib).take  
  if !object
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} has no holding from '#{bib}'")
  else
    marc = object.marc
    new_856 = MarcNode.new(Source, "856", "", "4#")
    ip = marc.get_insert_position("856")
    new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
    new_856.add(MarcNode.new(Source, "z", "[digitized version]", nil))
    marc.root.children.insert(ip, new_856)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} #{bib} new digitizalization with content '#{url}'")
    modified = true
    object.save if modified
  end
}

maintenance.execute process
