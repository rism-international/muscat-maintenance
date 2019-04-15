# encoding: UTF-8
#
puts "##################################################################################################"
puts "#######    ISSUE: Give 031 new number schema with 'ICCU' and add 040 language  ###################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 268).order(:id)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  add_040 = true
  record.suppress_reindex
  record_type = record.record_type
  source = Muscat::Marc.new(record)
  marc = source.marc
  marc.each_by_tag("040") do |tag|
    if tag.fetch_first_by_tag("b")
      add_040 = false
      next
    else
      tag.add(MarcNode.new(Source, "b", "ita", nil))
      tag.sort_alphabetically
      modified = true
    end
  end
  if add_040
    new_040 = MarcNode.new(Source, "040", "", "##")
    ip = marc.get_insert_position("040")
    new_040.add(MarcNode.new(Source, "b", "ita", nil))
    new_040.sort_alphabetically
    marc.root.children.insert(ip, new_040)
    modified = true
  end
  
  marc.each_by_tag("031") do |tag|
    next if tag.fetch_first_by_tag("c")
    new_a = "1"
    tag_a = tag.fetch_first_by_tag("a")
    new_b = tag_a.content rescue next
    tag_b = tag.fetch_first_by_tag("b")
    new_c = tag_b.content rescue next
    tag_a.content = new_a
    tag_b.content = new_b
    tag.add(MarcNode.new(Source, "c", "#{new_c}", nil))
    tag.sort_alphabetically
    modified = true
  end

  if modified
    record.marc = source.build_marc
    record.record_type = record_type
    record.save! rescue next
    maintenance.logger.info("#{maintenance.host}: ICCU #{record.id} new incipit order")
  end

}

maintenance.execute process
