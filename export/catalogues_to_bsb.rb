# encoding: UTF-8
puts "##################################################################################################"
puts "############################### Export catalogues to BSB OPAC ####################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
catalogues = Publication.order(:id).pluck(:id)

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open("/tmp/catalogues.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")
ofile.close
cnt = 0
res = []
bar = ProgressBar.new(catalogues.size)

catalogues.each do |s|
  record = Publication.find(s) rescue next
  begin
    marc = record.marc.to_xml_record({updated_at: record.updated_at })
    #marc = record.marc.to_xml_record(record.updated_at, nil, false)
  rescue
    next
  end
  doc_record = Nokogiri::XML.parse(marc.to_s) do |config|
      config.noblanks
  end

  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open("/tmp/catalogues.xml", "a+")
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

afile = File.open("/tmp/catalogues.xml", "a+")
res.each do |r|
  afile.write(r)
end
afile.write("\n</marc:collection>")
afile.close

