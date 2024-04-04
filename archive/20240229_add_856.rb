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
  hx = row[4].split(";")
  urlx = row[2].split(";")
  txtx = row[3].split(";")
  hx.zip(urlx, txtx).each do |e|
    res[e[0]] = {url: e[1], txt: e[2]}
  end
end

holdings = Holding.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(holdings)

process = lambda { |record|
  dict = res[record.id.to_s]

    record.marc.each_by_tag("856") do | tag |
      url = tag.fetch_first_by_tag("u")
      x = tag.fetch_first_by_tag("x").content
      z = tag.fetch_first_by_tag("z")
      if url && !z && x == "Other" && url.content.include?("permalink.obvsg.at")
        tag.add(MarcNode.new(Holding, "z", "bibliographic record", nil))
        tag.sort_alphabetically
        maintenance.logger.info("#{maintenance.host}: Holding ##{record.id} #{tag.to_s}")
        record.save
      end
    end
}

maintenance.execute process
