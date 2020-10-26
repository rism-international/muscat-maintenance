# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to ffm             #################################"
# puts "#########################   Expected collection size: 50.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

CSV.foreach(filename, :headers => true) do |row|
  res[row[0].to_i] = row[1].strip 
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
   

process = lambda { |record|
     modified = false
     url = res[record.id]
     if record.marc_source.include?(url)
       next
     end
     marc = record.marc
     new_856 = MarcNode.new(Source, "856", "", "4#")
     ip = marc.get_insert_position("856")
     new_856.add(MarcNode.new(Source, "u", "http://nbn-resolving.de/#{url}", nil))
     new_856.add(MarcNode.new(Source, "x", "Digitalization", nil))
     new_856.add(MarcNode.new(Source, "z", "Digital copy", nil))
     new_856.sort_alphabetically
     marc.root.children.insert(ip, new_856)
     maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content 'http://nbn-resolving.de/#{url}'")
     modified = true
     record.save if modified
}

maintenance.execute process
