# encoding: UTF-8
puts "##################################################################################################"
puts "################################## Export sources to BSB OPAC ####################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
sources = Source.where(:wf_stage => 1).pluck(:id)
#sources = Source.where('id > ?', 1001000000).where(:wf_stage => 1)
#sources = Source.where('id like ?', '4520%').pluck(:id)
#sources = Source.order("rand(id)").limit(100)

#maintenance = Muscat::Maintenance.new(sources)

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open("/tmp/sources.xml", "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")
ofile.close
cnt = 0
res = []
bar = ProgressBar.new(sources.size)

sources.each do |s|
  record = Source.find(s)
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
    nodes_774.each do |node|
      name = Source.find(node.content).name rescue next
      sfa = Nokogiri::XML::Node.new "marc:subfield", node
      sfa['code'] = 'a'
      sfa.content = name
      node << sfa
    end
    nodes_774 = nil
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
    holdings = nil
    all_holdings = nil
  end

  #doc = Nokogiri::XML.parse(doc_record.to_s) do |config|
  #  config.noblanks
  #end
  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open("/tmp/sources.xml", "a+")
    res.each do |r|
      afile.write(r)
    end
    res = []
    afile.close
  end
  #ofile.write(doc_record.root.to_xml :encoding => 'UTF-8')
  cnt += 1
  bar.increment!
#  binding.pry
  record = nil
  doc_record = nil
  sources.delete(s)
end


#process = lambda { |record|
  #binding.pry
#  sleep 0.4
  #doc_record = Nokogiri::XML.parse(record.marc.to_xml_record(record.updated_at, nil)) do |config|
  #  config.noblanks
  #end
=begin
  all_holdings = []
  if !record.holdings.empty?
    all_holdings = record.holdings
  elsif record.source_id
    all_holdings = Source.find(record.source_id).holdings
  end

  if record.record_type == 1
    nodes_774 = doc_record.xpath("//*[@tag='774']", NAMESPACE)
    nodes_774.each do |node|
      name = Source.find(node.content).name rescue next
      sfa = Nokogiri::XML::Node.new "marc:subfield", node
      sfa['code'] = 'a'
      sfa.content = name
      node << sfa
      node = nil
    end
    nodes_774 = nil
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
    holdings = nil
    all_holdings = nil
  end

  doc = Nokogiri::XML.parse(doc_record.to_s) do |config|
    config.noblanks
  end
=end
  #ofile.write(doc_record.root.to_xml :encoding => 'UTF-8')
  #doc_record = nil
  #doc = nil
  #record = nil
#}

#maintenance.execute process


ofile.write("\n</marc:collection>")
ofile.close

