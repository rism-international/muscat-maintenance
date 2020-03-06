# encoding: UTF-8
puts "##################################################################################################"
puts "############################### Export sigla for catalogue ########################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
institutions = Institution.where.not(:siglum => nil).order(:id).pluck(:id)
config = YAML.load_file("#{Rails.root}/config/editor_profiles/default/configurations/InstitutionLabels.yml")
country_hash = {}
config.each do |k,v| 
  if k =~ /[A-Z]{2}\-*/
    country_hash[k] = v["label"]["en"]
  end
end

File.write('/tmp/country.list', country_hash.values.sort.join("\n"))

# Should only run on dedicated local machine
exit unless Socket.gethostname == 'lab.rism'

ofile = File.open("/tmp/sigla.xml", "w")
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
  
  lx = doc_record.xpath("//*[local-name()='marc:datafield'][@tag='670']")
  lx.each do |e|
    e.remove
  end

  size = Institution.count_by_sql("select count(*) from sources_to_institutions where institution_id = #{record.id}")
  if size > 0
    tag = Nokogiri::XML::Node.new "marc:datafield", doc_record.root
    tag['tag'] = '670'
    tag['ind1'] = ' '
    tag['ind2'] = ' '
    sfa = Nokogiri::XML::Node.new "marc:subfield", doc_record.root
    sfa['code'] = 'a'
    sfa.content = size
    tag << sfa
    doc_record.root << tag
  end

  country = doc_record.xpath("//*[local-name()='marc:datafield'][@tag='043']/*[local-name()='marc:subfield'][@code='c']").first
  country.content = country_hash[country.text] if country
  
  geo = doc_record.xpath("//*[local-name()='marc:datafield'][@tag='034']")
  unless geo.empty?
    geo.each do |g|
      sf_f = g.xpath("*[local-name()='marc:subfield'][@code='f']").first.content rescue ""
      sf_d = g.xpath("*[local-name()='marc:subfield'][@code='d']").first.content rescue ""
      geo_content = "#{sf_f}, #{sf_d}"
      tag = Nokogiri::XML::Node.new "marc:datafield", doc_record.root
      tag['tag'] = '852'
      tag['ind1'] = ' '
      tag['ind2'] = ' '
      sfa = Nokogiri::XML::Node.new "marc:subfield", doc_record.root
      sfa['code'] = 'b'
      sfa.content = geo_content
      tag << sfa
      doc_record.root << tag
    end
  end

  res << (doc_record.root.to_xml :encoding => 'UTF-8')
  if cnt % 500 == 0
    afile = File.open("/tmp/sigla.xml", "a+")
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

afile = File.open("/tmp/sigla.xml", "a+")
res.each do |r|
  afile.write(r)
end
afile.write("\n</marc:collection>")
afile.close

