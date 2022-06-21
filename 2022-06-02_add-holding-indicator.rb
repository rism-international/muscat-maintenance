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

holdings = []
res.each do |e|
  holdings << Holding.where(source_id: e['001']).where(lib_siglum: 'GB-Lbl').where('created_at > ?', Time.parse('2022-03-01')).where(wf_owner: 0).pluck(:id)
end

holdings.flatten.uniq.each do |e|
  holding = Holding.find(e)
  marc = MarcHolding.new(holding.marc_source)
  marc.load_source(false)

  marc.each_by_tag("852") do |tag|
    if tag.indicator = ""
      node = MarcNode.new("holding", "852", "", "##")
      tag.children.reverse.each do |t|
        node.add_at(t, 0)
      end
      node.add(MarcNode.new(Source, "x", "30001581", nil))
      node.sort_alphabetically
      tag.destroy_yourself
      ip = marc.get_insert_position("852")
      marc.root.children.insert(ip, node)
    end
  end
  begin
    import_marc = MarcHolding.new(marc.to_marc)
    import_marc.import
    holding.marc = import_marc
    holding.save
  rescue => e
    $stderr.puts"Record could not save holding record for #{holding.source_id}:#{holding.id}"
    $stderr.puts e.message.blue
    next
  end
end

