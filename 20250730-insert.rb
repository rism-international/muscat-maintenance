# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Insert a1 enthalten_in   ##################################"
puts "#######################   Expected collection size: c.4.700      #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
require 'csv'

yaml = Muscat::Maintenance.yaml
bar = ProgressBar.new(yaml.size)
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
hostname = Socket.gethostname
res = []



CSV.open("myfile.csv", "w") do |csv|
  yaml.each do |e|
    a1 = e.keys.first
    puts a1
    search_string = "%A/I$c#{a1}%"
    value = e[a1].values.first
    record = Source.where('marc_source like ?', search_string).take
    begin
      CSV.open("t.csv", "ab") do |csv|
        csv << [record.id, a1, value]
        bar.increment!
      end
    rescue
      binding.pry
      bar.increment!
    end
  end
end

exit

CSV.open("myfile.csv", "w") do |csv|
  res.each do |i|
    csv << i
  end
end


exit

numbers.each do |e|
  modified = false
  _730a = ""
  record = Source.find(e) rescue next
  record_type = record.record_type
  new_marc = record.marc

  new_marc.each_by_tag("035") do |tag|
    tag.each_by_tag("a") do |subfield|
      a1_number = subfield.content
      dict = yaml.select{ |item| item.keys.first == a1_number }.first
      _730a = dict.values.first.values.first rescue next
    end
  end

  new_marc.each_by_tag("730") do |tag|
    tag.each_by_tag("a") do |subfield|
      if subfield.content == _730a
        tag.destroy_yourself
        modified = true
      end
    end
  end

  if modified 
    record.save!
    logger.info("#{hostname}: Print #{record.id} updated with migration data")
  end
  bar.increment!
end
