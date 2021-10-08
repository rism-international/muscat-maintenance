# encoding: UTF-8
puts "##################################################################################################"
puts "################################   Import E sources        #######################################"
puts "############################   Expected size: ca. 2.000       ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

ifile = "#{Rails.root}/housekeeping/maintenance/20210816-import.xml"
PaperTrail.request.disable_model(Publication)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
res = {}
doc = File.open(ifile) { |f| Nokogiri::XML(f)  }
ids = doc.xpath("//*[@tag='001']", NAMESPACE).map{|i| i.text.to_i}
doc.xpath("//marc:record").each do |i| 
  k = i.xpath("marc:controlfield[@tag='001']").first.text.to_i
  v = i.xpath("marc:datafield[@tag='999']/marc:subfield[@code='a']").first.text rescue nil
  res[k] = v
end

if File.exists?(ifile)
  import = MarcImport.new(ifile, "Source", 0)
  begin 
    import.import
  rescue
    puts "Error importing"
  end
  $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts ifile + " is not a file!"
end

user = User.find(257)

sx = Source.where(id: ids)
sx.update_all(:wf_stage => 0, :wf_audit => 1)
sx.update_all(wf_owner: user.id)


res.each do |k,v|
  next unless v
  record = Source.find(k) rescue next
  if v.starts_with?("Single")
    record.update(record_type: 2)
  elsif v.starts_with?("Individual")
    record.update(record_type: 2)
  elsif v.starts_with?("Collection")
    record.update(record_type: 1)
  else
    next
  end
end


#FIXME only
puts "#########################################################################"
puts "################ Updateing new imported sources   #######################"
puts "#########################################################################"


px = Person.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
px.each do |p|
  p.scaffold_marc
end
Person.where('created_at > ?', Time.now - 24.hours).where(wf_owner: 0).update_all(wf_owner: user.id, wf_stage: 0)


ix = Institution.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
ix.each do |i|
  i.scaffold_marc
end
Institution.where('created_at > ?', Time.now - 24.hours).where(wf_owner: 0).update_all(wf_owner: user.id, wf_stage: 0)

cx = Publication.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
end
Publication.where('created_at > ?', Time.now - 24.hours).where(wf_owner: 0).update_all(wf_owner: user.id, wf_stage: 0)

