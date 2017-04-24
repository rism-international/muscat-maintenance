# encoding: UTF-8
puts "##################################################################################################"
puts "################################### Export people to BSB OPAC ####################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
people = Person.order(:id).pluck(:id)

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open("/tmp/people.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")
ofile.close
cnt = 0
res = []
bar = ProgressBar.new(people.size)

people.each do |s|
  record = Person.find(s) rescue next
  begin
    marc = record.marc.to_xml_record(record.updated_at, nil, false)
  rescue
    next
  end
  doc_record = Nokogiri::XML.parse(marc) do |config|
      config.noblanks
  end

  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open("/tmp/people.xml", "a+")
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

afile = File.open("/tmp/people.xml", "a+")
res.each do |r|
  afile.write(r)
end
afile.write("\n</marc:collection>")
afile.close
