# encoding: UTF-8
puts "##################################################################################################"
puts "#####################    ISSUE tasks/#441: Add digitalization links ##############################"
puts "############################   Expected collection size: 250  ####################################"
puts "##################################################################################################"
puts ""

require 'csv'
require_relative "lib/maintenance"
res = {}
csv = CSV.read("#{Rails.root}/housekeeping/maintenance/20200506-bsb-digit.csv")
csv.each do |e|
  res[e[0].to_i] = {u: "http://nbn-resolving.de/urn/resolver.pl?urn=#{e[1]}", z: e[2], x: e[3]}
end

sources = Source.where(:id => res.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
modified = false
obj = res[record.id]
u = obj[:u]
x = "Digitalization"
z = "Digital copy"
marc = record.marc
new_856 = MarcNode.new(Source, "856", "", "4#")
ip = marc.get_insert_position("856")
new_856.add(MarcNode.new(Source, "u", "#{u}", nil))
new_856.add(MarcNode.new(Source, "x", "#{x}", nil))
new_856.add(MarcNode.new(Source, "z", "#{z}", nil))
new_856.sort_alphabetically
marc.root.children.insert(ip, new_856)
maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{u}'")
modified = true
record.save if modified
}

maintenance.execute process
