# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Add Links to OENB             #################################"
puts "#####################   Expected collection size: ca. 48.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
bar = ProgressBar.new(422)

def each_record(filename, &block)
  File.open(filename) do |file|
    Nokogiri::XML::Reader.from_io(file).each do |node|
      if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        yield(Nokogiri::XML(node.outer_xml, nil, "UTF-8"))
      end
    end
  end
end

ifile = "#{Rails.root}/housekeeping/maintenance/20221106-add_856.xml"

each_record(ifile) do | record |
  id = record.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text
  source = Source.find(id)
  marc = source.marc
  _856x = record.xpath("//marc:datafield[@tag='856']", NAMESPACE)
  _856x.each do | node |
    new_856 = MarcNode.new(Source, "856", "", "4#")
    ip = marc.get_insert_position("856")
    _856u = node.xpath("marc:subfield[@code='u']").text
    _856x = node.xpath("marc:subfield[@code='x']").text
    _856z = node.xpath("marc:subfield[@code='z']").text
    new_856.add(MarcNode.new(Source, "u", "#{_856u}", nil))
    new_856.add(MarcNode.new(Source, "x", "#{_856x}", nil))
    new_856.add(MarcNode.new(Source, "z", "#{_856z}", nil))
    new_856.sort_alphabetically
    marc.root.children.insert(ip, new_856)
  end
  source.save
  logger.info("#{host}: #{id} add 856" )
  bar.increment!
end



