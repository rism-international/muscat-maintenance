# encoding: UTF-8
require "nokogiri"
require "csv"
require "pry"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"

puts "##################################################################################################"
puts "###########################  ISSUE #: Import Musicat             #################################"
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

ifile = "./oen.original.xml"
ofile=File.open("./oen.xml", "w")
dnb_c = CSV.read("./dnb.csv").to_h

ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<collection xmlns="http://www.loc.gov/MARC21/slim">'+"\n")

each_record(ifile) do | record |
  id = record.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text
  ["100", "700", "710"].each do | tag |
    record.xpath("//marc:datafield[@tag='#{tag}']", NAMESPACE).each do | df |
      df.xpath("//marc:subfield[@code='0']", NAMESPACE).each do | zero |
        if zero && zero.content && zero.content.start_with?("(DE-588)")
          auth_id = dnb_c[zero.content.gsub("(DE-588)", "")]
          if auth_id
            puts "tag #{tag}: #{zero.content.gsub("(DE-588)", "")} - #{auth_id}"
            zero.content = auth_id
          else
            zero.remove
          end
        end
      end
    end
  end
  composer = record.xpath("//marc:datafield[@tag='100']/marc:subfield[@code='a']", NAMESPACE).first.text rescue "---"
  subfield = record.xpath("//marc:datafield[@tag='240']/marc:subfield[@code='a']", NAMESPACE).first.text rescue "---"
  File.write('./out.txt', "#{id}: #{composer}: #{subfield}\n", mode: 'a+')
  #open('./out.txt', 'a') { |f|
  #  puts "#{id}: #{composer}: #{subfield}" #if subfield.length > 254
  #}
  #uts "#{id}: #{composer}: #{subfield}" #if subfield.length > 254
  record_string = record.to_s
  doc = Nokogiri::XML.parse(record_string) do |config|
    config.noblanks
  end
  ofile.write(doc.remove_namespaces!.root.to_xml :encoding => 'UTF-8')
end

ofile.write("\n</collection>")
ofile.close


