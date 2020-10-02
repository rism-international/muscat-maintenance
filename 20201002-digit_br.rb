# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to br              #################################"
# puts "#########################   Expected collection size: 50.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

CSV.foreach(filename, :headers => true) do |row|
  rism_id = row[0].to_i
  url = row[1]
  if res[rism_id]
    res[rism_id] << url
  else
    res[rism_id] = [url]
  end
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  urls = res[record.id]
  modified = false
  urls.each do |url|
     if record.marc_source.include?(url)
       puts record.id
       next
     end
     marc = record.marc
     new_856 = MarcNode.new(Source, "856", "", "4#")
     ip = marc.get_insert_position("856")
     new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
     new_856.add(MarcNode.new(Source, "x", "Digitalization", nil))
     new_856.add(MarcNode.new(Source, "z", "Digitized source", nil))
     new_856.sort_alphabetically
     marc.root.children.insert(ip, new_856)
     maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{url}'")
     modified = true
  end
  record.save if modified
}

maintenance.execute process
