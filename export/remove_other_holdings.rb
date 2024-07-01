# encoding: UTF-8
require "nokogiri"
require "csv"
require "pry"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"

puts "##################################################################################################"
puts "###########################  ISSUE #: Remove other holdings      #################################"
puts "############################   Expected size: 2.300           ####################################"
puts "##################################################################################################"
puts ""

def each_record(filename, &block)
  File.open(filename) do |file|
    Nokogiri::XML::Reader.from_io(file).each do |node|
      if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        yield(Nokogiri::XML(node.outer_xml, nil, "UTF-8"))
      end
    end
  end
end

ifile = "./output.xml"
ofile=File.open("./output_without_holdings.xml", "w")
holding_id = "51066744"
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<collection xmlns="http://www.loc.gov/MARC21/slim">'+"\n")

each_record(ifile) do | record |
  siglum = record.xpath("//marc:datafield[@tag='852']/marc:subfield[@code='a']", NAMESPACE)
  if siglum.size == 1 && siglum.text != "D-Ru"
    next
  end
  holdings = record.xpath("///marc:subfield[@code='3']", NAMESPACE)
  holdings.each do |h|
    if h.text != holding_id
      h.parent.remove
    end
  end
  record_string = record.to_s
  doc = Nokogiri::XML.parse(record_string) do |config|
    config.noblanks
  end
  ofile.write(doc.root.to_xml :encoding => 'UTF-8')
end

ofile.write("\n</collection>")
ofile.close


