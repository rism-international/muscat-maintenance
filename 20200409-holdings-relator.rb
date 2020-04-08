# encoding: UTF-8
puts "##################################################################################################"
puts "########### ISSUE    Change relator code in 700 from 'dub' to 'asn' ##############################"
puts "#####################   Expected collection size: ca. 34  ########################################"
puts "#####################   Uses Sunsport:Solr for filtering   #######################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


holdings = Holding.find_by_sql("SELECT id FROM holdings where marc_source REGEXP '=700[^\n]*\[[.$.]]4dub'").pluck(:id)

maintenance = Muscat::Maintenance.new(holdings)

process = lambda { |id|
  record = Holding.find(id)
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
  maintenance.logger.info("#{maintenance.host}: Holding ##{record.id} $700$4 'dub' changed to 'asn'.")
}

maintenance.execute process
