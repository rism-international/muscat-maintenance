# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Change template with composite       ################################"
puts "##########################   Expected collection size: ca.50    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(id: Holding.pluck(:collection_id).uniq.compact)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.change_template_to(11)
  #record.update(record_type: 11)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} switched to composite template")
}

maintenance.execute process
