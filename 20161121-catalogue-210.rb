# encoding: UTF-8
# ISSUE #4: Correct short title with false further title in 210 - adding to 240
# Expected collection size: 56
#
require_relative "lib/maintenance"

catalogues = Catalogue.where("name like ?", "%; %")
maintenance = Muscat::Maintenance.new(catalogues)

process = lambda { |record|
  further_title = ""
  short_title = ""
  marc = record.marc
  
  marc.each_by_tag("210") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    short_title = a_tag.content.split("; ").first
    further_title = a_tag.content.split("; ")[1..-1].join("; ")
    a_tag.content = short_title
  end

  marc.each_by_tag("240") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    a_tag.content += ". #{further_title}"
  end

  record.name = short_title
  record.save
  maintenance.logger.info("#{maintenance.host}: Catalogue ##{record.id} $210a splitted.")
}

maintenance.execute process
