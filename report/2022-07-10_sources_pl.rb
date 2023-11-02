dir = "#{Rails.root}/housekeeping/maintenance"
numbers = File.read("#{dir}/plsa.txt").split("\n")
res = ["<?xml version=\"1.0\" encoding=\"UTF-8\"?>", "<marc:collection xmlns:marc=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">"]

basket = []

numbers.each do |num|
  number = num.strip
  if basket.include?(number)
    puts "### DUPLICATE #{number}"
    next
  else
    basket << number.to_i
  end
  puts number
  begin
    source = Source.find(number)
  rescue
    binding.pry
  end
  res << source.marc.to_xml_record(nil, nil, true) rescue next
end
res << "</marc:collection>" 
File.write("#{dir}/plsa.xml", res.join("\n"))
