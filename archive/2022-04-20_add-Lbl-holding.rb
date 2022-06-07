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
  res << { '001' => e[0], '852a' => e[1], '852c' => e[2], '500a1' => e[3], '500a2' => e[4],
            '856u' => e[5], '856x' => e[6], '856z' => e[7]}
end

res.each do |e|
  record = Source.where(id: e['001']).take
  holding = Holding.new
  marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
  marc.load_source false
  node = marc.root.fetch_first_by_tag("852")
  node.add_at(MarcNode.new("holding", "a", e['852a'], nil), 0)
  node.add_at(MarcNode.new("holding", "c", e['852c'], nil), 0)
  node.sort_alphabetically

  node856 = MarcNode.new("holding", "856", "", "##")
  node856.add_at(MarcNode.new("holding", "u", e['856u'], nil), 0)
  node856.add_at(MarcNode.new("holding", "x", e['856x'], nil), 0)
  node856.add_at(MarcNode.new("holding", "z", e['856z'], nil), 0)
  node856.sort_alphabetically
  marc.root.children.insert(marc.get_insert_position("856"), node856)

  unless e['500a1'].blank?
    node5001 = MarcNode.new("holding", "500", "", "##")
    node5001.add_at(MarcNode.new("holding", "a", e['500a1'], nil), 0)
    marc.root.children.insert(marc.get_insert_position("500"), node5001)
  end

  unless e['500a2'].blank?
    node5002 = MarcNode.new("holding", "500", "", "##")
    node5002.add_at(MarcNode.new("holding", "a", e['500a2'], nil), 0)
    marc.root.children.insert(marc.get_insert_position("500"), node5002)
  end

  holding.marc = marc
  holding.source = record
         
  begin
    holding.save
  rescue => e
    $stderr.puts"SplitHoldingRecords could not save holding record for #{source.id}"
    $stderr.puts e.message.blue
    next
  end


end

