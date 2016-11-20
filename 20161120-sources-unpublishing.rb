# encoding: UTF-8
# ISSUE #1: Setting all records of 456055* to unpublished by request of BeLu
require_relative "lib/maintenance"

collection = Source.where("id like ?", "456055%").where(:wf_stage => 1)
maintenance = Muscat::Maintenance.new(collection)

process = lambda { |record|
  record.update(:wf_stage => 'inprogress')
  maintenance.logger.info("#{maintenance.host}: #{record.id} updated to publish.")
}

maintenance.execute process
