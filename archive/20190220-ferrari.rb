# encoding: UTF-8
puts "##################################################################################################"
puts "#####################    ISSUE tasks/#441: Add digitalization links ##############################"
puts "############################   Expected collection size: 184  ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml

sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
modified = false
url = yaml[record.id]
marc = record.marc
new_856 = MarcNode.new(Source, "856", "", "4#")
ip = marc.get_insert_position("856")
new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
new_856.add(MarcNode.new(Source, "x", "Digitalization", nil))
new_856.sort_alphabetically
marc.root.children.insert(ip, new_856)
maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{url}'")
modified = true
record.save if modified
}

maintenance.execute process
