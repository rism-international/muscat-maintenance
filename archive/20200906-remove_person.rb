# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Remove orphan person from work links      #######################"
puts "############################   Expected collection size: 3.300  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

mapping = {"40220402": "30002570", "40200959": "30002621", "40206090": "30004854"}

works = Work.where("marc_source like ? or marc_source like ? or marc_source like ?", "%40220402%", "%40200959%", "%40206090%")

maintenance = Muscat::Maintenance.new(works)

process = lambda { |record|

  modified = false
  new_marc = MarcWork.new(record.marc_source)
  new_marc.load_source(false)
  person = ""

  new_marc.root.fetch_all_by_tag("100").each do |e|
    p = e.fetch_first_by_tag("0")
    person = p.content
    p.content = mapping[p.content]
    modified = true
  end

  new_marc.root.fetch_all_by_tag("400").each do |e|
    p = e.fetch_first_by_tag("0")
    person = p.content
    p.content = mapping[p.content]
    modified = true
  end

  if modified
    import_marc = MarcWork.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: Work #{record.id} replaced person '#{person}'")
    rescue 
      maintenance.logger.info("#{maintenance.host}: Work ERROR #{record.id} replacing '#{person}'")
    end
  end

}

maintenance.execute process
