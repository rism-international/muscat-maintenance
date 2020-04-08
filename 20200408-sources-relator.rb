# encoding: UTF-8
puts "##################################################################################################"
puts "########### ISSUE    Change relator code in 700 from 'dub' to 'asn' ##############################"
puts "#####################   Expected collection size: ca. 500 ########################################"
puts "#####################   Uses Sunsport:Solr for filtering   #######################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

count = Source.count
sx = Source.solr_search do
  fulltext "dub", :fields => '7004'
  paginate :page => 1, :per_page => count
end
sources = sx.results

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("700") do |tag|
    a_tag = tag.fetch_first_by_tag("4")
    if a_tag && a_tag.content == 'dub'
      a_tag.content = 'asn'
      modified = true
    end
  end
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} $700$4 'dub' changed to 'asn'.")
}

maintenance.execute process
