# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Import Moravian          #################################"
puts "############################   Expected size: 3.500           ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
%x( tar -xzvf housekeeping/maintenance/20171214-import_moravian.xml.tar.gz -C /tmp/ )

ifile = "/tmp/20171214-import_moravian.xml"

yml = YAML.load_file("housekeeping/maintenance/20171214-import_moravian.yml")
ids = yml.values

Catalogue.paper_trail.disable
Holding.paper_trail.disable
Institution.paper_trail.disable
Person.paper_trail.disable
Source.paper_trail.disable

source_file = ifile
model = "Source"
from = 0
if File.exists?(source_file)
  import = MarcImport.new(source_file, model, from.to_i)
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts source_file + " is not a file!"
end

sx = Source.where(:id => ids)

sx.each do |s|
  s.reload
  s.update(:wf_stage => 0, :wf_audit => 1, :wf_owner => 141)
  s.reindex
end

px = Person.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
px.each do |p|
  p.scaffold_marc
  p.reindex
end

ix = Institution.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
ix.each do |i|
  i.scaffold_marc
  i.reindex
end

cx = Catalogue.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
  c.reindex
end


