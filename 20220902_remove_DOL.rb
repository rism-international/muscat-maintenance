# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Remove DOL            ##################################"
puts "############################   Expected collection size: 4.000  ##################################"
puts "######################## Remove old Digital Object links         #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where('marc_source like ?', "%Digital Object Link%")

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  datafields = record.marc.by_tags("500")
  record_modified = false
  size = 0
  datafields.each do |tag|
    modified = false
    subfields = tag.fetch_all_by_tag("a")
    if subfields.size > 1
      next
    else
      subfields.each do |a_tag|
        if a_tag.content =~ /Digital Object Link: http:\/\/dl.rism.info\/DO\/[0-9]+.jpg$/
          modified = true
          record_modified = true
        else
          next
        end
      end
    end
    if modified
      maintenance.logger.info("#{maintenance.host}: #{record.id} #{tag} removed")
      tag.destroy_yourself
      size += 1
    end
  end

  if record_modified
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} #{size} DOLinks removed")
    rescue
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id}")
    end
  end

}

maintenance.execute process

#puts "INDEXING"
#Sunspot.index(sources)
#Sunspot.commit
