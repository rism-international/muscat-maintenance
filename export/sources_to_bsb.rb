# encoding: UTF-8
puts "##################################################################################################"
puts "################################## Export sources to BSB OPAC ####################################"
puts "##################################################################################################"
puts ""

require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
#sources = Source.where('id > ?', 1001000000).where(:wf_stage => 1)
sources = Source.where(:wf_stage => 1)
#sources = Source.order("rand(id)").limit(100)

maintenance = Muscat::Maintenance.new(sources)

# Should only run on dedicated local machine
exit unless maintenance.host == 'lab.rism'

ofile = File.open("/tmp/sources.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")

process = lambda { |record|
  doc_record = Nokogiri::XML.parse(record.marc.to_xml_record(record.updated_at, nil)) do |config|
    config.noblanks
  end
  all_holdings = []
  if !record.holdings.empty?
    all_holdings = record.holdings
  elsif record.source_id
    all_holdings = Source.find(record.source_id).holdings
  end

  if record.record_type == 1
    nodes_774 = doc_record.xpath("//*[@tag='774']", NAMESPACE)
    binding.pry
    nodes_774.each do |node|
      name = Source.find(node.content).name rescue next
      sfa = Nokogiri::XML::Node.new "marc:subfield", node
      sfa['code'] = 'a'
      sfa.content = name
      node << sfa
    end
  end


  unless all_holdings.empty?
    holdings = []
    all_holdings.each do |h|
      doc_holding =  Nokogiri::XML.parse(h.marc.to_xml)
      holdings << doc_holding.xpath("//marc:datafield[@tag='852']", NAMESPACE)
    end
    # Sort holding by sigla 
    holdings.sort_by { |h| h.xpath("marc:subfield[@code='a']").first.content }.each do |h|
      doc_record.root << h
    end
  end

  doc = Nokogiri::XML.parse(doc_record.to_s) do |config|
    config.noblanks
  end
  ofile.write(doc.root.to_xml :encoding => 'UTF-8')
}

maintenance.execute process

ofile.write("\n</marc:collection>")
ofile.close

