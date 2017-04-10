# encoding: UTF-8
puts "##################################################################################################"
puts "############     ISSUE #25: Change ownership to SBB Musikabteilung       #########################"
puts "############                Expected size: 22.277                        #########################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

rsh = User.find(75)
sbb = User.where(:name => 'SBB Musikabteilung').take

sources = Source.where(:wf_owner => rsh).where('created_at < ?', DateTime.parse("2016-11-10"))
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.update(:wf_owner => sbb.id)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} ownership -> SBB.")
}

maintenance.execute process
