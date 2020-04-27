# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Remove holdings from subentries      ##########################"
puts "#########################   Expected collection size: ca. 150   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("select * from sources s where s.source_id is not NULL and s.record_type=3 and s.id in (select source_id from holdings)")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  ch = false
  parent = Source.find(record.source_id)
  parent.holdings.each do |h|
    if h.lib_siglum.starts_with?("CH-")
      ch = true
    end
  end
  if !ch
    record.holdings.each do |holding|
      holding.destroy
    end
    maintenance.logger.info("#{maintenance.host}: Holdings deleted from subentry #{record.id}")
  end

}

maintenance.execute process
