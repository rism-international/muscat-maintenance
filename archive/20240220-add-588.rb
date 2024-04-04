# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BLB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}
CSV.foreach(filename, :headers => true) do |e|
  res[e[1]] = "#{e[6]} #{e[7]}"
end

holdings = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(holdings)

process = lambda { |record|
  new_588 = MarcNode.new(Source, "588", "", "##")
  ip = record.marc.get_insert_position("588")
  new_588.add(MarcNode.new(Source, "a", res[record.id.to_s], nil))
  record.marc.root.children.insert(ip, new_588)
  record.save
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 588 with content '#{res[record.id.to_s]}'")
}

maintenance.execute process
