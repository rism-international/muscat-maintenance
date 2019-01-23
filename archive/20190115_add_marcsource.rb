# encoding: UTF-8
puts "##################################################################################################"
puts "############     ISSUE #415: Add marc_source to people                   #########################"
puts "############                Expected size: ca. 5.000                     #########################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

px = Person.where(marc_source: nil)
maintenance = Muscat::Maintenance.new(px)

process = lambda { |record|
  #puts record.id
  record.scaffold_marc
  maintenance.logger.info("#{maintenance.host}: Person ##{record.id} add marc_source")
}
px.update_all(wf_owner: 4)
px.update_all(wf_stage: 0)

maintenance.execute process
