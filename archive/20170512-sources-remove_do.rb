# encoding: UTF-8
puts "##################################################################################################"
puts "###########ISSUE #27: Remove DO link from 500 if the is a new DO in Muscat   #####################"
puts "###########################     Expected collection size: 6.627            #######################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"


sx = Sunspot.search(Source) do 
  fulltext "Digital Object Link"
  paginate :page => 1, :per_page => 10000
end

ids = sx.hits.map{|hit| hit.result.id}
sources = Source.where(:id => ids)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  new_links = record.digital_objects.pluck(:attachment_file_name)
  marc = record.marc
  marc.each_by_tag("500") do |n|
    content = n.fetch_first_by_tag("a").content rescue nil
    if content.start_with?("Digital Object Link: ")
      old_link_filename = content.split("/").last
      if new_links.include?(old_link_filename)
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} removed old link #{old_link_filename} in 500 because new link exist")
        n.destroy_yourself
        modified = true
      else
        maintenance.logger.warn("#{maintenance.host}: Source ##{record.id} NOT removing old link #{old_link_filename} in 500 because new link doesn't exist")
      end
    end
  end
  record.save if modified
}

maintenance.execute process

