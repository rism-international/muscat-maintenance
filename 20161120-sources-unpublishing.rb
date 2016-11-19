# encoding: UTF-8
# ISSUE #1: Setting all records of 456055* to unpublished by request of Bernhard Lutz
require_relative "lib/maintenance"

collection = Source.where("id like ?", "456055%").where(:wf_stage => 1)

process = Proc.new do |record|
  record.update(:wf_stage => 'inprogress')
end


maintenance = Muscat::Maintenance.new(collection)
maintenance.execute process
