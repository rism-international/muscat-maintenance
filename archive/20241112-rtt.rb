# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "###################   ISSUE: Add shelfmark to D-Rtt              #################################"
# puts "#########################   Expected collection size: 400       ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}
CSV.foreach(filename, :headers => true) do |e|
  if res[e[2]]
    res[e[2]] << e[3]
  else
    res[e[2]] = [e[3]]
  end
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
tags = %w(852)

process = lambda { |record|
  modified = false
  holdings = record.holdings.where(lib_siglum: "D-Rtt")
  holdings.each_with_index do |holding, index|
    holding.marc.each_by_tag("852") do |tag|
      sf = tag.fetch_first_by_tag("c")
      sf.content = res[record.id.to_s][index]
      modified = true
    end
    holding.save if modified
  end
  maintenance.logger.info("#{maintenance.host}: ##{record.id} holdings with '#{res[record.id.to_s].join}'")
 }


maintenance.execute process
