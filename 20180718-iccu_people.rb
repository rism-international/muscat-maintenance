# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Import ICCU people       #################################"
puts "############################   Expected size: 110.500         ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
%x( tar -xjvf housekeeping/maintenance/20180718-iccu_people.tar.bz2 -C /tmp/ )

ifile = "/tmp/20180718-iccu_people.xml"

Catalogue.paper_trail.disable
Holding.paper_trail.disable
Institution.paper_trail.disable
Person.paper_trail.disable
Source.paper_trail.disable

if File.exists?(ifile)
  import = MarcImport.new(ifile, "Person", 0)
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts ifile + " is not a file!"
end

sx = Person.where(wf_owner: 1).where('created_at > ?', Time.now - 48.hours)
sx.update_all(:wf_stage => 0, :wf_audit => 1, :wf_owner => 4)

