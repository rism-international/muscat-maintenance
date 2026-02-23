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
id_filename = "#{File.dirname($0)}/20251124-tit.csv"
res = []

data = CSV.read(filename, headers: :first_row, :col_sep => ";")
ids = CSV.read(id_filename, headers: :first_row, :col_sep => ";").to_a.flatten
multiple = ""

data.each do |e|
  res << { 'series' => e[0],
           'rismid' => e[1],
           '852a' => e[2], 
           '852q' => e[3], 
           '852c' => e[4],
           '856u' => e[5], 
           '856z' => e[6],
           '856x' => e[7], 
           '691a' => e[8], 
           '691n' => e[9], 
           '500a' => e[10],
  }
end

def find_source(dict)
  series, rismid = dict["series"].to_s.strip, dict["rismid"].to_s.strip
  if dict["series"]
    #source = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=510[^\n]*\[[.$.]]c#{series.gsub("/", "\/")}'")
    #source = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=510[^\n]*\[[.$.]]c#{series.gsub("/", "\/")}$'")
    source = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=510[^\n]*\[[.$.]]c.*#{series.strip.gsub("/", "\/")}\\r\\n'")
  else
    source = Source.where(id: rismid)
  end
  return source
end

def combine(dict,*tags)
  x = (dict.select{|k,v| v.to_s.include?("@@")}).slice(*tags)
  y = x.values.map{|r| r.split("@@")}
  return y.transpose
end

res.each do |e|
  record = find_source(e)
  puts e
  #binding.pry
  puts record.first.marc.all_values_for_tags_with_subtag("510", "c") rescue "---"
  #puts record.first.marc.root.fetch_all_by_tag("510").to_s
  #puts record.first.marc.first_occurance("510").to_s
  #puts record.first.marc.root.fetch_first_by_tag("510").to_s
  puts record.first.id rescue "TILT"
  if record.size > 1
    puts "+++"
    record.each do |d|
      puts d.id
      puts d.marc.all_values_for_tags_with_subtag("510", "c") rescue "-----"
      #puts record.first.marc.root.fetch_all_by_tag("510")
      #puts d.marc.root.fetch_first_by_tag("510")
    end
      #puts "#{record.first.id};#{record[1..-1].pluck(:id)[0..10].join(',')} (#{record.size})"
  end
  #uts record.first.id rescue puts e
  #e = combine(e)
  #binding.pry unless e.empty?
=begin
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
=end

end

