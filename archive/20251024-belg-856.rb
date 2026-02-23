# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BLB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[0].to_i
  res[id] = [row[1]]
  res[id] << row[2] if row[2]
  res[id] << row[3] if row[3]
  res[id] << row[4] if row[4]
  res[id] << row[5] if row[5]
  res[id] << row[6] if row[6]
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
   

process = lambda { |record|
     modified = false
     urls = res[record.id]
     urls.each do |url|
       if record.marc_source.include?(url.split('://').last)
         next
       end
       marc = record.marc
       new_856 = MarcNode.new(Source, "856", "", "4#")
       ip = marc.get_insert_position("856")
       new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
       new_856.add(MarcNode.new(Source, "x", "Digitized", nil))
       new_856.add(MarcNode.new(Source, "z", "Digital copy", nil))
       new_856.sort_alphabetically
       marc.root.children.insert(ip, new_856)
       modified = true
     end
     if modified
       maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{urls.join}'")
       record.save if modified
     end
}

maintenance.execute process
