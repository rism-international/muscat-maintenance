# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Check and replace Herbst collection    ##############################"
puts "#####################   Expected collection size: 913     ########################################"
puts "##################################################################################################"
puts ""

=begin
  ok        245: Replace completely and publish all subfields
  260$c: Replace completely 
  300$a: Replace completely and publish all subfields
  ok        500: add when not already present in RISM
  690: Add
  ok        505: add and move to 500
  ok        506: add
  ok        630: Add and move to 500.
  650 _7: Add and move to 657
  700: replace all
  710: replace all
  852: replace all
  Add link to MMF record in WorldCat if possible
=end

require_relative "lib/maintenance"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
SCHEMA_FILE="conf/MARC21slim.xsd"

def each_node(filename, &block)
  File.open(filename) do |file|
    Nokogiri::XML::Reader.from_io(file).each do |node|
      if node.name == 'record' || node.name == 'marc:record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        yield(Nokogiri::XML(node.outer_xml, nil, "UTF-8"))
      end
    end
  end
end

bar = ProgressBar.new(913)
each_node("#{Rails.root}/housekeeping/maintenance/20180418_herbst.xml") do |node|
  begin
    rismid = node.xpath("//marc:datafield[@tag='856']/marc:subfield[@code='u']", NAMESPACE)[0].content.split("id=").last 
  rescue 
    #puts "WITHOUT #{without_rism_id += 1}"
    next
  end
  record = Source.find(rismid)
  marc = record.marc
  puts "OLD:-----------"
  puts marc
  new_245 = node.xpath("//marc:datafield[@tag='245']/marc:subfield").map{|e| e.content}.join(" ") 
  marc.each_by_tag("245") do |e|
    e.fetch_first_by_tag("a").content = new_245
  end
 

  existing_500 = []
  marc.each_by_tag("500") do |e|
    existing_500 << e.fetch_first_by_tag("a").content 
  end
  # add 657
  node.xpath("//marc:datafield[@tag='650' and @ind2='7']").each do |e|
    festival = e.xpath("marc:subfield[@code='a']").first.content
    new_node = MarcNode.new(Source, "657", "", "##")
    ip = marc.get_insert_position("657")
    new_node.add(MarcNode.new(Source, "a", "#{festival}", nil))
    marc.root.children.insert(ip, new_node)
  end



  # Add 500
  %w( 500 505 506 630 ).each do |e|
    existing = false
    new_content = node.xpath("//marc:datafield[@tag='#{e}']/marc:subfield").map{|field| field.content}.join(" ")
    next if new_content.empty?
    existing_500.each do |existing_content|
      if existing_content.start_with?(new_content[0..10])
        marc.each_by_tag("500") do |tag|
          existing_tag = tag.fetch_first_by_tag("a")
          if new_content.start_with?(existing_tag.content[0..10] )
            existing_tag.content = new_content     
            existing = true
          end
        end
      end
    end
    unless existing
      new_500 = MarcNode.new(Source, "500", "", "##")
      ip = marc.get_insert_position("500")
      new_500.add(MarcNode.new(Source, "a", "#{new_content}", nil))
      marc.root.children.insert(ip, new_500)
    end
  end
  puts "NEW: -----"
  puts marc
  bar.increment!
   
end



