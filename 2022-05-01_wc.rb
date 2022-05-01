# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Lbl holding info           ################################"
# puts "#########################   Expected collection size: 1.000     ##################################"
# puts "##################################################################################################"
# puts ""
#

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = []

data = CSV.read(filename, headers: :first_row, :col_sep => "\t")

data.each do |e|
  res << {'001' => e[0], '852c' => e[4], '856u' => e[1], '856x' => e[2], '856z' => e[3]}
end

ids = res.map{|e| e["001"]}
sources = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(sources)
res.each do |e|
  record = Source.where(id: e['001']).take
  holding = record.holdings.where(lib_siglum: 'US-Wc').take
  marc = holding.marc

  marc.each_by_tag("852") do |n|
    c = n.fetch_first_by_tag("c") rescue nil
    c.content = e["852c"]
  end

  if e["856u"]
    new_856 = MarcNode.new(Holding, "856", "", "4#")
    ip = marc.get_insert_position("856")
    new_856.add(MarcNode.new(Holding, "u", "#{e['856u']}", nil))
    new_856.add(MarcNode.new(Holding, "x", "#{e['856x']}", nil))
    new_856.add(MarcNode.new(Holding, "z", "#{e['856z']}", nil))
    marc.root.children.insert(ip, new_856)
  end

  holding.save
  maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id}:Holding #{holding.id} modified")


end

