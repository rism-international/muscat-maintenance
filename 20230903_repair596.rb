# encoding: UTF-8
puts "##################################################################################################"
puts "#############################        Split 596$a          ########################################"
puts "############################   Expected size: ca. 1.700       ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=596[^\n]*\[[.$.]]a'")
maintenance = Muscat::Maintenance.new(records)
msg = ""

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("596") do |tag|
    tag_a = tag.fetch_first_by_tag("a")
    if tag_a && tag_a.content.include?(":")
      old_tag = tag.dup
      tag_b = tag.fetch_first_by_tag("b")
      if !tag_b
        tag_a_content, tag_b_content = tag_a.content.split(":")
        tag_a.content = tag_a_content.strip
        tag.add(MarcNode.new(record.class, "b", "#{tag_b_content.strip}", nil))
        tag.sort_alphabetically
        modified = true
      end
      msg = "#{old_tag} ==> #{tag}"
    end
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id}: #{msg}")
    record.save
  end
}

maintenance.execute process
