# encoding: UTF-8
puts "##################################################################################################"
puts "############################### Export institutions to BSB OPAC ##################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
institutions = Institution.order(:id).pluck(:id)

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open("/tmp/institutions.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")
ofile.close
cnt = 0
res = []
bar = ProgressBar.new(institutions.size)

institutions.each do |s|
  record = Institution.find(s) rescue next
  begin
    marc = record.marc.to_xml_record(record.updated_at, nil, false)
  rescue
    next
  end
  doc_record = Nokogiri::XML.parse(marc) do |config|
      config.noblanks
  end

  tag = Nokogiri::XML::Node.new "marc:controlfield", doc_record.root
  tag['tag'] = '008'
  created_at = record.created_at.strftime("%y%m%d")
  tag.content = "#{created_at}n|||||||a|||              a"
  begin 
    doc_record.xpath("//*[@tag>'005']", NAMESPACE).first.add_previous_sibling(tag)
  rescue
    doc_record.xpath("//*[@tag>'003']", NAMESPACE).first.add_previous_sibling(tag)
  end

  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open("/tmp/institutions.xml", "a+")
    res.each do |r|
      afile.write(r)
    end
    res = []
    afile.close
  end
  cnt += 1
  bar.increment!
  record = nil
  doc_record = nil
end

afile = File.open("/tmp/institutions.xml", "a+")
res.each do |r|
  afile.write(r)
end
afile.write("\n</marc:collection>")
afile.close

