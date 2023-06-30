# encoding: UTF-8
puts "##################################################################################################"
puts "#################      Remove tag if 510$a=A/I and no $c         #################################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=510[^\n]*\[[.$.]]a'")

maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  tag_s = ""
  record.marc.each_by_tag("510") do |tag|
    tag_a = tag.fetch_first_by_tag("a").content rescue ""
    tag_c = tag.fetch_first_by_tag("c").content rescue nil
    if tag_a.include?("A/I") && tag_c.blank?
      tag_s = tag.to_s
      tag.destroy_yourself
      modified = true
    end
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: ##{record.id} #{tag_s}") if modified
    record.save
  end
}

maintenance.execute process
