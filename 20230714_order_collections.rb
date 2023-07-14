# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE : Reorder entries with PiKaDo collections  ###########################"
puts "############################   Expected collection size: 12.000  ##################################"
puts "########################                                         #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(record_type: 1).where('created_at < ?', Time.parse("2007-01-01"))

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  children = record.child_sources.pluck(:id).sort
  res = []
  datafields = record.marc.by_tags("774")
  datafields.each do |tag|
    sf = tag.fetch_first_by_tag("w")
    res << sf.content
  end
  unsorted = res.map{|e| e.to_i}
  if unsorted != children
    modified = true
    sorted = datafields.sort_by{|e| e.to_s}
    record.marc.by_tags("774").each do |tag|
      tag.destroy_yourself
    end
    sorted.each do |tag|
      new_774 = tag
      ip = record.marc.get_insert_position("774")
      record.marc.root.children.insert(ip, new_774)
    end
  end

  if modified
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} tag 774 sorted")
    rescue
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id}")
    end
  end

}

maintenance.execute process
