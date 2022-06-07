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

  if marc.has_tag?("260")
    marc.each_by_tag("260") do |n|
      puts n
      c = n.fetch_first_by_tag("c") rescue nil
      if c
        puts record.id
      else
        n.add_at(MarcNode.new("source", "c", e['260c'], nil), 0)
        break
      end
    end
  else
    node260 = MarcNode.new("source", "260", "", "##")
    node260.add_at(MarcNode.new("source", "c", e['260c'], nil), 0)
    node260.add_at(MarcNode.new("source", "8", "01", nil), 0)
    marc.root.children.insert(marc.get_insert_position("260"), node260)
  end

  node500 = MarcNode.new("source", "500", "", "##")
  node500.add_at(MarcNode.new("source", "a", e['500a'], nil), 0)
  marc.root.children.insert(marc.get_insert_position("500"), node500)
 

  begin
    record.save
  rescue
    puts "RECORD #{record.id} CANNOT BE SAVED"
  end

end

