# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Change link with Schrank2     #################################"
# puts "#########################   Expected collection size: 3.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = []
old_link = "http://www.schrank-zwei.de"
new_link = "https://hofmusik.slub-dresden.de"

CSV.foreach(filename) do |row|
  res << row[0].to_i
end

sources = Source.where(:id => res)
maintenance = Muscat::Maintenance.new(sources)
   

process = lambda { |record|
     modified = false
     marc = record.marc
     marc.each_by_tag("856") do |tag|
      a_tag = tag.fetch_first_by_tag("u")
      if a_tag.content.include?(old_link)
        a_tag.content = new_link
        modified = true
      end
    end

    marc.each_by_tag("500") do |tag|
      a_tag = tag.fetch_first_by_tag("a")
      if a_tag.content.include?("www.schrank-zwei.de")
        a_tag.content = a_tag.content.gsub("www.schrank-zwei.de", new_link)
        modified = true
      end
    end
    
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} changed link with content '#{new_link}'")
    record.save if modified
}

maintenance.execute process
