# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Change *m33 etc with unicode         ##########################"
puts "#########################   Expected collection size: ca. 680   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources where marc_source like '%*m33%' or marc_source like '%*n33%'")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("245") do |tag|
    tag.each_by_tag("a") do |sf|
      if sf.content =~ /\*[mn]33/
        new_content = sf.content.gsub("*m33", "m̅").gsub("*n33", "n̅")
        sf.content = new_content
        modified = true
      end
    end
  end
  marc.each_by_tag("246") do |tag|
    tag.each_by_tag("a") do |sf|
      if sf.content =~ /\*[mn]33/
        new_content = sf.content.gsub("*m33", "m̅").gsub("*n33", "n̅")
        sf.content = new_content
        modified = true
      end
    end
  end
  marc.each_by_tag("500") do |tag|
    tag.each_by_tag("a") do |sf|
      if sf.content =~ /\*[mn]33/
        new_content = sf.content.gsub("*m33", "m̅").gsub("*n33", "n̅")
        sf.content = new_content
        modified = true
      end
    end
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: replaced protype in #{record.id}")
    record.save #rescue next
  end
}

maintenance.execute process
