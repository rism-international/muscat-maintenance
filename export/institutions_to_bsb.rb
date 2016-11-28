# encoding: UTF-8
puts "##################################################################################################"
puts "############################## Export institutions to BSB OPAC ###################################"
puts "##################################################################################################"
puts ""

require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
#sources = Source.where('id > ?', 1001000000).where(:wf_stage => 1)
institutions = Institution.all
maintenance = Muscat::Maintenance.new(institutions)

# Should only run on dedicated local machine
exit unless maintenance.host == 'lab.rism'

ofile = File.open("/tmp/institutions.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")

process = lambda { |record|
  doc_record = Nokogiri::XML.parse(record.marc.to_xml_record(record.updated_at, nil)) do |config|
    config.noblanks
  end
  doc = Nokogiri::XML.parse(doc_record.to_s) do |config|
    config.noblanks
  end
  ofile.write(doc.root.to_xml :encoding => 'UTF-8')
}


maintenance.execute process

ofile.write("\n</marc:collection>")
ofile.close

