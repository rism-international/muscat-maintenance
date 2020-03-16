# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Add '[no indication]' as 852$c            ##########################"
puts "#########################   Expected collection size: 42.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
sources = Source.where('record_type=? or record_type=?', 1, 2).where(shelf_mark: "")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("852") do |tag|
    next if tag.fetch_first_by_tag("c")
    tag.add(MarcNode.new(Source, "c", "[no indication]", nil))
    tag.sort_alphabetically
    modified = true
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: Record ##{record.id} added $c [no indication") if modified
    record.save rescue next
  end
}

maintenance.execute process

