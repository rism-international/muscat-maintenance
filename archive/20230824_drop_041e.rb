# encoding: UTF-8
puts "##################################################################################################"
puts "#############################        Remove 041$e         ########################################"
puts "############################   Expected size: ca. 1.700       ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=041[^\n]*\[[.$.]]e'")

maintenance = Muscat::Maintenance.new(records)

message = ""

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("041") do |tag|
    tag_a = tag.fetch_first_by_tag("a")
    tag_e = tag.fetch_first_by_tag("e")
    next unless tag_e
    if !tag_a
      new_sf = tag.add(MarcNode.new(Source, "a", "#{tag_e.content}", nil))
      message = "ADDED #{tag_e} => #{new_sf}"
      tag_e.destroy_yourself
      tag.sort_alphabetically
      modified = true
    elsif tag_e.content == tag_a.content
      message = "DELETED #{tag_e} == #{tag_a}"
      tag_e.destroy_yourself
      modified = true
    else
      message = "MOVED #{tag_e} => $a"
      new_sf = tag.add(MarcNode.new(Source, "a", "#{tag_e.content}", nil))
      tag.sort_alphabetically
      tag_e.destroy_yourself
      #tag_a = tag_e
      #tag_e.destroy_yourself
      modified = true
    end
    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id} #{message}") if modified
  end

  if modified
    record.save
  end
}

maintenance.execute process
