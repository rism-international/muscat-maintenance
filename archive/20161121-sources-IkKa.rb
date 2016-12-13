# encoding: UTF-8
puts "##################################################################################################"
puts "############     ISSUE #2: Set some sigla records to ownership IkKa      #########################"
puts "############                Expected size: 5187                          #########################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

user = User.where(:name => 'Ikarus Kaiser').take.id
libraries = %w(A-WIL A-WEY A-ALT A-GAS A-MÜ A-NAT A-ROB A-SFI A-SCHA A-SCHW A-TAI A-AST A-BL A-KRB A-LIpsm A-LIsp A-LOH A-MUN A-NEU A-REI A-SGG)

sources = Source.where(:lib_siglum => libraries).where(:wf_owner => 1)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.update(:wf_owner => user)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} ownership -> IkKa.")
}

maintenance.execute process
