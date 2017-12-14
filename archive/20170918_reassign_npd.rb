# encoding: UTF-8
puts "##################################################################################################"
puts "############ISSUE 542: Changed npd leader from coll to source template   #########################"
puts "############                Expected size: 1.560                         #########################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.update(:record_type => 2)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} record_type -> 2")
}

maintenance.execute process
