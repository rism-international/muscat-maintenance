# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Import ICCU people       #################################"
puts "############################   Expected size: 110.500         ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
%x( tar -xjvf housekeeping/maintenance/20180718-iccu_people.tar.bz2 -C /tmp/ )
exit
ifile = "/tmp/20180718-iccu_people.xml"

PaperTrail.request.disable_model(Catalogue)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

if File.exists?(ifile)
  import = MarcImport.new(ifile, "Person", 0)
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts ifile + " is not a file!"
end

sx = Person.where(wf_owner: 1).where('created_at > ?', Time.now - 48.hours)
sx.update_all(:wf_stage => 0, :wf_audit => 1, :wf_owner => 4)

