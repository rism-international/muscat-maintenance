# encoding: UTF-8
puts "##################################################################################################"
puts "################################## Export sources to BSB OPAC ####################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
sources = Source.where(:wf_stage => 1).order(:id).pluck(:id)
filename = "/tmp/sources.xml"
#sources = Source.where(:wf_stage => 1).order(:id).limit(1000).pluck(:id)

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open(filename, "w")
ofile.write('<?xml version="1.0" encoding="UTF-8"?>'+"\n"+'<marc:collection xmlns:marc="http://www.loc.gov/MARC21/slim">'+"\n")
ofile.close
cnt = 0
res = []
bar = ProgressBar.new(sources.size)

sources.each do |s|
  record = Source.find(s) rescue next
  begin
    marc = record.marc.to_xml_record(record.updated_at, nil, true)
  rescue
    next
  end
  doc_record = Nokogiri::XML.parse(marc) do |config|
      config.noblanks
  end
  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open(filename, "a+")
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

afile = File.open(filename, "a+")
res.each do |r|
  afile.write(r)
end
afile.write("\n</marc:collection>")
afile.close

=begin
  all_holdings = []
  if !record.holdings.empty?
    all_holdings = record.holdings
  elsif record.source_id
    all_holdings = Source.find(record.source_id).holdings rescue []
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
=end
  #TODO whe should drop the dublet entries in 500 with Digital Object Link prefix for older records
=begin
  if !record.digital_objects.empty? && record.id >= 1001000000
    record.digital_objects.each do |image|
      path = image.attachment.path.gsub("/path/to/the/digital/objects/directory/", "http://muscat.rism.info/")
      tag = Nokogiri::XML::Node.new "marc:datafield", doc_record.root
      tag['tag'] = '500'
      tag['ind1'] = ' '
      tag['ind2'] = ' '
      sfa = Nokogiri::XML::Node.new "marc:subfield", doc_record.root
      sfa['code'] = 'a'
      sfa.content = "#{image.description}: #{path}"
      tag << sfa
      doc_record.xpath("//*[@tag>'500']", NAMESPACE).first.add_previous_sibling(tag)
    end
  end
=end

