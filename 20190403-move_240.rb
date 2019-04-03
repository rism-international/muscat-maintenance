# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################    ISSUE: Move 240 with dots to 730 with 'ICCU'  ############################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 268)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  title_730 = nil
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.each_by_tag("240") do |tag|
    title_tag = tag.fetch_first_by_tag("a")
    title = title_tag.content
    if title.include?(".")
      title_tag.content = title.split(".").first
      tag.fetch_first_by_tag("0").destroy_yourself
      title_730 = title
      modified = true
    end
  end

  if title_730
    new_730 = MarcNode.new(Source, "730", "", "##")
    ip = new_marc.get_insert_position("730")
    new_730.add(MarcNode.new(Source, "a", "#{title_730}", nil))
    new_730.add(MarcNode.new(Source, "g", "ICCU", nil))
    new_730.sort_alphabetically
    new_marc.root.children.insert(ip, new_730)
  end
  
  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    record.save! rescue next
    maintenance.logger.info("#{maintenance.host}: ICCU #{record.id} add 730 #{title_730}")
  end

}

maintenance.execute process
