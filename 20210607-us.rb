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
  res[row[0].to_i] = row[2].strip 
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
   

process = lambda { |record|
     holding = record.holdings.where(lib_siglum: 'US-Su').take
     modified = false
     url = res[record.id]
     if holding.marc_source.include?(url)
       next
     end
     marc = holding.marc
     new_856 = MarcNode.new(Holding, "856", "", "4#")
     ip = marc.get_insert_position("856")
     new_856.add(MarcNode.new(Holding, "u", "#{url}", nil))
     new_856.add(MarcNode.new(Holding, "x", "Digitalization", nil))
     new_856.add(MarcNode.new(Holding, "z", "Digitized copy", nil))
     new_856.sort_alphabetically
     marc.root.children.insert(ip, new_856)
     maintenance.logger.info("#{maintenance.host}: Holding ##{record.id} new digitizalization with content '#{url}'")
     modified = true
     holding.save if modified
}

maintenance.execute process
