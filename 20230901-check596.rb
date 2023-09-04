# encoding: UTF-8
puts "##################################################################################################"
puts "#############################        Check 596$a          ########################################"
puts "############################   Expected size: ca. 15.700      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=596[^\n]*\[[.$.]]a'")

maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("596") do |tag|
    tag_a = tag.fetch_first_by_tag("a")
    if tag_a && tag_a.content.starts_with?("RISM")
      old_tag = tag_a.dup
      new_content = tag_a.content.gsub("RISM ", "")
      tag_a.content = new_content
      new_tag = tag_a
      modified = true
      maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id} #{old_tag} ==> #{new_tag}")
    end
  end

  if modified
    record.save
  end
}

maintenance.execute process
