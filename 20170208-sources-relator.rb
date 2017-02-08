# encoding: UTF-8
puts "##################################################################################################"
puts "########### ISSUE #8 Change relator code in 710 from 'asn' to 'oth' ##############################"
puts "#####################   Expected collection size: 5.496   ########################################"
puts "#####################   Uses Sunsport:Solr for filtering   #######################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

count = Source.count
sx = Source.solr_search do
  fulltext "asn", :fields => '7104'
  paginate :page => 1, :per_page => count
end
sources = sx.results

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("710") do |tag|
    a_tag = tag.fetch_first_by_tag("4")
    if a_tag && a_tag.content == 'asn'
      a_tag.content = 'oth'
        modified = true
    end
  end
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} $710$4 'asn' changed to 'oth'.")
}

maintenance.execute process
