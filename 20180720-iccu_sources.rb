# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Import ICCU sources      #################################"
puts "############################   Expected size: 227.500         ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
%x( tar -xjvf housekeeping/maintenance/20180720-iccu_sources.tar.bz2 -C /tmp/ )

ifile = "/tmp/20180720-iccu_sources.xml"

Catalogue.paper_trail.disable
Holding.paper_trail.disable
Institution.paper_trail.disable
Person.paper_trail.disable
Source.paper_trail.disable

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
sx.update_all(:wf_stage => 0, :wf_audit => 1)

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


