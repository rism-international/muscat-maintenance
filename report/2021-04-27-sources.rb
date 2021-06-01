dir = "#{Rails.root}/housekeeping/maintenance/report"
numbers = File.read("#{dir}/2021-04-27-sources.txt").split("\n")
res = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">"]

numbers.each do |number|
  source = Source.find(number) rescue next
  res << source.marc.to_xml_record(nil, nil, true) rescue next
end
res << "</marc:collection>" 
File.write("#{dir}/out.xml", res.join("\n"))
