# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Check and replace Herbst collection    ##############################"
puts "#####################   Expected collection size: 913     ########################################"
puts "##################################################################################################"
puts ""

=begin
  245: Replace completely and publish all subfields
  260$c: Replace completely 
  300$a: Replace completely and publish all subfields
  500: add when not already present in RISM
  690: Add
  505: add and move to 500
  506: add
  630: Add and move to 500.
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
  new_245 = node.xpath("//marc:datafield[@tag='245']/marc:subfield").map{|e| e.content}.join(" ") 
  binding.pry
  
  
  
  bar.increment!






   
end



