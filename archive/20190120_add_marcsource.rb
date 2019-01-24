# encoding: UTF-8
puts "##################################################################################################"
puts "##########    ISSUE #425: Add marc_source to institutions   ######################################"
puts "############                Expected size: ca. 500                   #############################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

px = Institution.where(marc_source: nil)
maintenance = Muscat::Maintenance.new(px)

process = lambda { |record|
  record.scaffold_marc
  maintenance.logger.info("#{maintenance.host}: Institution ##{record.id} add marc_source")
}
px.update_all(wf_stage: 0)

maintenance.execute process
