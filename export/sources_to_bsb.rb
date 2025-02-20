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
err = 0

sources.each do |s|
  record = Source.find(s) #rescue next
  ###################################################################
  #######          Custom local changes for BSB             #########
  ###################################################################
  # Adding created at 008
  created = record.created_at.strftime("%y%m%d")
  _008_content = "#{created}##################################"
  tag_008 = MarcNode.new(@model, "008", _008_content, nil)
  begin
    record.marc.root.children.insert(record.marc.get_insert_position("008"), tag_008)
  rescue
    puts "#{err += 1} MISSING WORK: #{record.id}"
    #next
  end

  # FIX to include holding.source_id at $o and description at $a with composite
  if record.record_type == 11
    begin
      record.marc.each_by_tag("774") do |node|
        holding_node = node.fetch_first_by_tag("4")
        if holding_node
          holding_id = node.fetch_first_by_tag("w").content #rescue nil
          holding = Holding.find(holding_id) #rescue next
          holding_source = Source.find(holding.source_id) #rescue next
          node.add(MarcNode.new(Source, "a", holding_source.name, nil))
          node.add(MarcNode.new(Source, "o", holding_source.id, nil))
        else
          source_id = node.fetch_first_by_tag("w").content #rescue nil
          source = Source.find(source_id)
          node.add(MarcNode.new(Source, "a", source.name, nil))
        end
      end
    rescue
      next
    end
  end

  # FIX to display references to folloup prints in 785 (as with 774)
  if record.record_type == 8
    record.referring_sources.each do |followup_print|
      followup_print.marc.each_by_tag("775") do |node|
        ref_id = node.fetch_first_by_tag("w").content #rescue nil
        if ref_id and ref_id == record.id
          new_785 = MarcNode.new(Source, "785", "", "10")
          ip = record.marc.get_insert_position("785")
          new_785.add(MarcNode.new(Source, "a", followup_print.name, nil))
          new_785.add(MarcNode.new(Source, "w", followup_print.id, nil))
          record.marc.root.children.insert(ip, new_785)
        end
      end
    end
  end
  ########################################################################

  begin
    marc = record.marc.to_xml_record({updated_at: record.updated_at, holdings: true })
  rescue
    #next
  end
  doc_record = Nokogiri::XML.parse(marc.to_s) do |config|
      config.noblanks
  end
  res << (doc_record.root.to_xml :encoding => 'UTF-8') rescue binding.pry
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

