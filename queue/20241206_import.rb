# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #: Import Fitzwilliam         #################################"
puts "###########################   Expected size: 8.000            ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

%x( tar -xjvf housekeeping/maintenance/20241206_import.tar.bz2 -C /tmp/  )
source_file = "/tmp/20241206_import.xml"
#source_file = "#{Rails.root}/housekeeping/maintenance/20241206_import.xml"
user = User.where('name like ?', "%Ward%").take
PaperTrail.request.disable_model(Publication)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

model = "Source"
#from = 0
if File.exists?(source_file)
  import = MarcImport.new(source_file, model, {first: 0, last: 999999, index: true})
  import.import
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts source_file + " is not a file!"
end

sx = Source.where('id between ? and ?', 457001200, 457002000)

sx.update_all(:wf_stage => 1, :wf_audit => 1, :wf_owner => user.id)
Sunspot.index(sx)
Sunspot.commit

px = Person.where('created_at > ?', Time.now - 24.hours).where(:marc_source => nil)
px.each do |p|
  puts p.id
  p.scaffold_marc
  p.update(wf_owner: user.id)
  p.reindex
end

ix = Institution.where('created_at > ?', Time.now - 24.hours).where(:marc_source => nil)
ix.each do |i|
  puts i.id
  i.scaffold_marc
  i.update(wf_owner: user.id)
  i.reindex
end

cx = Publication.where('created_at > ?', Time.now - 24.hours).where(:marc_source => nil)
cx.each do |c|
  puts c.id
  c.scaffold_marc
  c.update(wf_owner: user.id)
  c.reindex
end
