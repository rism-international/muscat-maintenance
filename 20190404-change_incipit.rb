# encoding: UTF-8
#
puts "##################################################################################################"
puts "###################    ISSUE: Give 031 new number schema with 'ICCU'  ############################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 268)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("031") do |tag|
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
    record.save! rescue next
    maintenance.logger.info("#{maintenance.host}: ICCU #{record.id} new incipit order")
  end

}

maintenance.execute process
