# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Check and replace Herbst collection    ##############################"
puts "#####################   Expected collection size: 913     ########################################"
puts "##################################################################################################"
puts ""

=begin
  ok        245: Replace completely and publish all subfields
  ok        260$c: Replace completely 
  300$a: Replace completely and publish all subfields
  ok        500: add when not already present in RISM
  ok        690: Add
  ok        505: add and move to 500
  ok        506: add
  ok        630: Add and move to 500.
  ok        650 _7: Add and move to 657
  ok        700: replace all
  ok        710: replace all
  ok        852: replace all
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
  ref_id = node.xpath("//marc:controlfield[@tag='001']").first.content.gsub(/[a-z]*/, "")
    
  record = Source.find(rismid)
  record_type = record.record_type
  marc = record.marc
  new_245 = node.xpath("//marc:datafield[@tag='245']/marc:subfield").map{|e| e.content}.join(" ")
  begin
  marc.each_by_tag("245") do |e|
    e.fetch_first_by_tag("a").content = new_245
  end
  rescue 
    next
  end
 
  existing_500 = []
  marc.each_by_tag("500") do |e|
    existing_500 << e.fetch_first_by_tag("a").content 
  end
  # add 657
  node.xpath("//marc:datafield[@tag='650' and @ind2='7']").each do |e|
    festival = e.xpath("marc:subfield[@code='a']").first.content
    new_node = MarcNode.new("source", "657", "", "##")
    ip = marc.get_insert_position("657")
    new_node.add_at(MarcNode.new("source", "a", "#{festival}", nil),0)
    marc.root.children.insert(ip, new_node)
  end

  node.xpath("//marc:datafield[@tag='260']/marc:subfield[@code='c']", NAMESPACE).each do |e|
    existing_260 = false
    marc.each_by_tag("260") do |tag|
      existing_260 = true
      existing_260c = tag.fetch_first_by_tag("c")
      if existing_260c
        existing_260c.content = e.content
      else
        tag.add_at(MarcNode.new("source", "c", e.content, nil),0)
      end
    end
    unless existing_260
      new_node = MarcNode.new("source", "260", "", "##")
      ip = marc.get_insert_position("260")
      new_node.add_at(MarcNode.new("source", "c", e.content, nil),0)
      marc.root.children.insert(ip, new_node)
    end
  end

  #replace 300
  marc.by_tags("300").each {|t| t.destroy_yourself}
  node.xpath("//marc:datafield[@tag='300']").each do |df|
    new_datafield = MarcNode.new("source", "300", "", "##")
    df.xpath("marc:subfield").each do |sf|
      code = sf["code"]
      content = sf.content
      new_datafield.add_at(MarcNode.new("source", "#{code}", "#{content}", nil),0)
    end
    new_datafield.add_at(MarcNode.new("source", "8", "01", nil),0)
    ip = marc.get_insert_position("300")
    marc.root.children.insert(ip, new_datafield)
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
      new_500 = MarcNode.new("source", "500", "", "##")
      new_500.add_at(MarcNode.new("source", "a", "#{new_content}", nil), 0)
      ip = marc.get_insert_position("500")
      marc.root.children.insert(ip, new_500)
    end
  end

  marc.by_tags("700").each {|t| t.destroy_yourself}
  marc.by_tags("710").each {|t| t.destroy_yourself}

  #replace 700 and 710
  %w( 700 710 ).each do |e|
    node.xpath("//marc:datafield[@tag='#{e}']").each do |df|
      new_datafield = MarcNode.new("source", "#{e}", "", "##")
      df.xpath("marc:subfield").each do |sf|
        code = sf["code"]
        content = sf.content
        content = content.gsub(/[.,]$/, '')
        new_datafield.add_at(MarcNode.new("source", "#{code}", "#{content}", nil),0)
      end
      ip = marc.get_insert_position("#{e}")
      marc.root.children.insert(ip, new_datafield)
    end
  end

  #replace 852
  marc.by_tags("852").each {|t| t.destroy_yourself}
  node.xpath("//marc:datafield[@tag='852']").each do |df|

    new_datafield = MarcNode.new("source", "852", "", "##")
    df.xpath("marc:subfield").each do |sf|
      code = sf["code"]
      code = "c" if code == "p"
      content = sf.content
      content = content.gsub(/[.,]$/, '')
      new_datafield.add_at(MarcNode.new("source", "#{code}", "#{content}", nil),0)
    end
    new_datafield.add_at(MarcNode.new("source", "x", "30002512", nil),0)
    ip = marc.get_insert_position("852")
    marc.root.children.insert(ip, new_datafield)
  end

  #690
  s_titles = []
  marc.each_by_tag("690") do |tag|
    s_titles << tag.fetch_first_by_tag("a").content
  end
  node.xpath("//marc:datafield[@tag='690']", NAMESPACE).each do |e|
    existing = false
    new_node = MarcNode.new("source", "690", "", "##")
    ip = marc.get_insert_position("690")
    e.xpath("marc:subfield").each do |subfield|
      if subfield.attr("code")=="a"  && s_titles.include?(subfield.content.unicode_normalize)
        existing = true
      end
      new_node.add_at(MarcNode.new("source", subfield.attr("code"), subfield.content.unicode_normalize, nil),0)
    end
    marc.root.children.insert(ip, new_node) unless existing
  end


  new_856 = MarcNode.new("holding", "856", "", "##")
  new_856.add_at(MarcNode.new("holding", "u", "https://moravianmusic.on.worldcat.org/oclc/#{ref_id}", nil), 0)
  new_856.add_at(MarcNode.new("holding", "z", "Original catalogue entry", nil), 0)
  new_856.sort_alphabetically
  marc.root.children.insert(marc.get_insert_position("856"), new_856)

  import_marc = MarcSource.new(marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  record.marc = import_marc
  record.record_type = record_type
  record.save
  bar.increment!
   
end



