# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BLB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

sources = Source.where(:record_type => 11)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("593") do |tag|
    tag_a = tag.fetch_first_by_tag("a")
    if tag_a && tag_a.content == "Print"
      tag_a.content = "Composite"
      modified = true
    end
  end
    
  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} changed 593$a to 'Composite'")
    record.save
  end
}

maintenance.execute process
