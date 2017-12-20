# encoding: UTF-8
puts "##################################################################################################"
puts "#################### Change ownership of migrated catalog to Falletta  ###########################"
puts "#####################   Expected collection size: 32.921  ########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
cx = Catalogue.where(wf_owner: 1)
maintenance = Muscat::Maintenance.new(cx)

process = lambda { |record|
  record.update(wf_owner: 60)
  maintenance.logger.info("#{maintenance.host}: #{record.id}: Ownership changed to Falletta")
}

maintenance.execute process
