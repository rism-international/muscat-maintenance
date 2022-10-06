# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #: Import Musicat             #################################"
puts "############################   Expected size: 2.300           ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

ifile = "#{Rails.root}/housekeeping/maintenance/20220908-import_musicat.xml"

PaperTrail.request.disable_model(Publication)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

ids = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20220908-import_musicat.yml")

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

sx = Source.where(id: ids)

sx.each do |s|
  begin
    s.update(:wf_stage => 1, :wf_audit => 1, :wf_owner => 500)
  rescue
    next
  end
  #s.reindex
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

cx = Publication.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
  c.reindex
end


