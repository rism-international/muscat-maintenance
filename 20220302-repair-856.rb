# encoding: UTF-8
puts "##################################################################################################"
puts "#################      Add and change 856$x with Sources and Holdings         ####################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Holding.find_by_sql("SELECT * FROM holdings where marc_source REGEXP '=856[^\n]*\[[.$.]]z'") + Source.find_by_sql("SELECT * FROM sources where marc_source REGEXP '=856[^\n]*\[[.$.]]z'")

maintenance = Muscat::Maintenance.new(records)

terms = %w(digitized Digitized digital Digital Digitisation Manuscriptorium)

regexp = Regexp.union(terms)


process = lambda { |record|
  modified = false
  changed = ""
  old_content = ""
  record.marc.each_by_tag("856") do |tag|
    tag_x = tag.fetch_first_by_tag("x") 
    tag_z = tag.fetch_first_by_tag("z")

    next unless tag_z
    next unless regexp.match(tag_z.content)

    if tag_x 
      if tag_x.content != "Other"
        next
      else
        old_content = tag_x.content
        tag_x.content = "Digitized"
        modified = true
        changed = "changed from '$x#{old_content}' to"
      end
    else
      tag.add(MarcNode.new(record.class, "x", "Digitized", nil))
      tag.sort_alphabetically
      modified = true
      changed = "created"
    end

    maintenance.logger.info("#{maintenance.host}: #{record.class} ##{record.id} '$z#{tag_z.content}' #{changed} '$xDigitized'") if modified
  
  end

  #if modified
  #  record.save
  #end
}

maintenance.execute process
