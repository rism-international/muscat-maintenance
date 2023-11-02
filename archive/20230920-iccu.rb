# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Check and replace ICCU                 ##############################"
puts "#####################   Expected collection size: 15.000  ########################################"
puts "##################################################################################################"
puts ""


#260$a, 260$b, 260$c, 300$a, 300$c, 593$a, 593$b, 592$a#
#
#




require_relative "lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(15734)

def each_node(filename, &block)
  File.open(filename) do |file|
    Nokogiri::XML::Reader.from_io(file).each do |node|
      if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        yield(Nokogiri::XML(node.outer_xml, nil, "UTF-8"))
      end
    end
  end
end

def replace_subfield(marc, tag, code, new_content)
  df = marc.first_occurance(tag)
  if df && !new_content
    sf = df.fetch_first_by_tag(code)
    sf.destroy_yourself if sf
    if df.children.size == 0
      df.destroy_yourself
    end
  elsif !df && new_content
    df = MarcNode.new(Source, tag, "", "##")
    ip = marc.get_insert_position(tag)
    marc.root.children.insert(ip, df)
    df.add(MarcNode.new(Source, code, new_content, nil))
  elsif !df && !new_content
    return
  elsif df && new_content
    sf = df.fetch_first_by_tag(code)
    if sf
      sf.content = new_content
    else
      df.add(MarcNode.new(Source, code, new_content, nil))
    end
  end
end

each_node("#{Rails.root}/housekeeping/maintenance/20230920-iccu.xml") do |node|
  bar.increment!
  obj = {}
  obj["id"] = node.xpath("//marc:controlfield[@tag='001']").first.content
  obj["260$a"] = node.xpath("//marc:datafield[@tag='260']/marc:subfield[@code='a']").first.content.strip rescue nil
  obj["260$b"] = node.xpath("//marc:datafield[@tag='260']/marc:subfield[@code='b']").first.content.strip rescue nil
  obj["260$c"] = node.xpath("//marc:datafield[@tag='260']/marc:subfield[@code='c']").first.content.strip rescue nil
  obj["300$a"] = node.xpath("//marc:datafield[@tag='300']/marc:subfield[@code='a']").first.content.strip rescue nil
  obj["300$c"] = node.xpath("//marc:datafield[@tag='300']/marc:subfield[@code='c']").first.content.strip rescue nil
  obj["593$a"] = node.xpath("//marc:datafield[@tag='593']/marc:subfield[@code='a']").first.content.strip rescue nil
  obj["593$b"] = node.xpath("//marc:datafield[@tag='593']/marc:subfield[@code='b']").first.content.strip rescue nil
  obj["592$a"] = node.xpath("//marc:datafield[@tag='592']/marc:subfield[@code='a']").first.content.strip rescue nil
  obj["999$a"] = node.xpath("//marc:datafield[@tag='999']/marc:subfield[@code='a']").map{|e| e.content.strip } unless node.xpath("//marc:datafield[@tag='999']/marc:subfield[@code='a']").empty?
  #obj = obj.compact
  source = Source.find(obj["id"]) rescue next
#  tags = obj.keys.select{|e| e =~ /_/}.map{|e| e[1..-3]}
  marc = source.marc
  old_tags = marc.by_tags_with_order(["260", "300", "593", "592", "500"]).join("---").gsub("\r", "").gsub("\n", "").dup
  obj.each do |k,v|
    next if k == "id"
    if k == "999$a"
      v.each do |c|
        new_500 = MarcNode.new(Source, "500", "", "##")
        ip = marc.get_insert_position("500")
        new_500.add(MarcNode.new(Source, "a", c, nil))
        marc.root.children.insert(ip, new_500)
      end
    else
      tag, code= k.split("$")
      replace_subfield(marc, tag, code, v)
    end
  end
  new_tags = marc.by_tags_with_order(["260", "300", "593", "592", "500"]).join("---").gsub("\r", "").gsub("\n", "")
  table_tags = obj.map{|k,v| "#{k}#{v}   ##"}.join
  logger.info("\n#{table_tags}::: \n#{old_tags} :::==>::: \n#{new_tags}\n\n")
  source.save
end



