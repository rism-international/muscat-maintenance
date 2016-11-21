# encoding: UTF-8
# ISSUE #4: Correct short title with false further title in 210 - adding to 240
# Expected collection size: 56
#
require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
user = User.where(:name => 'Stephan Hirsch').take.id
sources = Source.where(:id => yaml)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.update(:wf_stage => 'inprogress', :wf_owner => user)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} ownership -> StHi.")
}

maintenance.execute process
