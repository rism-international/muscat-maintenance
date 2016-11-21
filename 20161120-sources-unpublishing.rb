# encoding: UTF-8
puts "##################################################################################################"
puts "#######   ISSUE #1: Setting all records of 456055* to unpublished by request of BeLu   ###########"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where("id like ?", "456055%").where(:wf_stage => 1)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.update(:wf_stage => 'inprogress')
  maintenance.logger.info("#{maintenance.host}: #{record.id} updated to unpublish.")
}

maintenance.execute process
