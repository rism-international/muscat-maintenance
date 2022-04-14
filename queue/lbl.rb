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
  res << { '001' => e[0], '260c' => e[1], '500a' => e[2] }
end

res.each do |e|
  record = Source.where(id: e['001']).take

  marc = record.marc

  marc.each_by_tag("260") do |n|
    puts n
    c = n.fetch_first_by_tag("c") rescue nil
    if c
      puts record.id
      binding.pry

    end
  end

  #binding.pry

=begin  
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

  if e["500a1"]
    new_500 = MarcNode.new(Holding, "500", "", "4#")
    ip = marc.get_insert_position("500")
    new_500.add(MarcNode.new(Holding, "a", "#{e['500a1']}", nil))
    marc.root.children.insert(ip, new_500)
  end

  if e["500a2"]
    new_500 = MarcNode.new(Holding, "500", "", "4#")
    ip = marc.get_insert_position("500")
    new_500.add(MarcNode.new(Holding, "a", "#{e['500a2']}", nil))
    marc.root.children.insert(ip, new_500)
  end
=end

end

