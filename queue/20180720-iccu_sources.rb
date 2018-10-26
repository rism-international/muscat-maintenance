# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Import ICCU sources      #################################"
puts "############################   Expected size: 227.500         ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
%x( tar -xjvf housekeeping/maintenance/20180720-iccu_sources.tar.bz2 -C /tmp/ )

ifile = "/tmp/20180720-iccu_sources.xml"

PaperTrail.request.disable_model(Catalogue)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

if File.exists?(ifile)
  import = MarcImport.new(ifile, "Source", 0)
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts ifile + " is not a file!"
end

#FIXME only
puts "#########################################################################"
puts "################ Updateing new imported sources   #######################"
puts "#########################################################################"

sx = Source.where('id between ? and ?', 850600000, 850900000)
sx.update_all(:wf_stage => 0, :wf_audit => 1, :wf_owner => 268)

px = Person.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
px.each do |p|
  p.scaffold_marc
end

ix = Institution.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
ix.each do |i|
  i.scaffold_marc
end

cx = Catalogue.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
end


