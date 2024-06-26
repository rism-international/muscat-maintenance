# encoding: UTF-8
puts "##################################################################################################"
puts "############ISSUE #2: Set dropped records to unpublish and ownership StHi#########################"
puts "############                Expected size: 300                           #########################"
puts "##################################################################################################"
puts " "

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
