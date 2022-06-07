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
  holdings = Holding.where(source_id: e['0001']).where(lib_siglum: 'GB-Lbl').where('created_at > ?', Time.parse('2022-03-01'))
  holdings.each do |holding|
    puts holding.id
    holding.marc.each_by_tag("852") do |tag|
      if tag.indicator = ""
        node = MarcNode.new("holding", "852", "", "##")
        tag.children.each do |t|
          node.add_at(t, nil, 0)
        end
      end
    end
    binding.pry
    begin
      #holding.save
    rescue => e
      $stderr.puts"SplitHoldingRecords could not save holding record for #{source.id}"
      $stderr.puts e.message.blue
    next
    end
  end
end

