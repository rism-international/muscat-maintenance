# encoding: UTF-8
puts "##################################################################################################"
puts "#############      Remove tag if 510$a=B/I and no $c with edition content  #######################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

records = Source.where('id like ?', "993%").where(record_type: 3)

maintenance = Muscat::Maintenance.new(records)

collections = []

process = lambda { |record|
  modified = false
  tag_s = ""
  record.marc.each_by_tag("510") do |tag|
    tag_a = tag.fetch_first_by_tag("a").content rescue ""
    tag_c = tag.fetch_first_by_tag("c").content rescue nil
    if tag_a.include?("B/I") && tag_c.blank?
      tag_s = tag.to_s
      if collections.include?(record.source_id)
        maintenance.logger.info("#{maintenance.host}: ##{record.id} #{tag_s}")
        tag.destroy_yourself
        modified = true
      else
        coll = Source.find(record.source_id)
        coll.marc.each_by_tag("510") do |ctag|
          ctag_a = ctag.fetch_first_by_tag("a").content rescue ""
          ctag_c = ctag.fetch_first_by_tag("c").content rescue ""
          if ctag_a.include?("B/I") && !ctag_c.blank?
            collections << coll.id
            maintenance.logger.info("#{maintenance.host}: ##{record.id} #{tag_s}")
            modified = true
            tag.destroy_yourself
          end
        end
      end
    end
  end

  if modified
    record.save
  end
}

maintenance.execute process
