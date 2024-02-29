# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE : Change Siglum for ICCU     ##################################"
puts "############################   Expected collection size: 9.000  ##################################"
puts "########################    Inherit siglum from collection       #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


#sources = Source.where(wf_owner: 268).where(record_type: 1)

#maintenance = Muscat::Maintenance.new(sources)

#process = lambda { |record|
#  shelfmark = record.marc.get_siglum_and_shelf_mark[1]
#  next if shelfmark == "[no indication]"
#
#  record.child_sources.each do | child |
#    child_shelfmark = child.marc.get_siglum_and_shelf_mark[1]
#    next if child_shelfmark != "[no indication]"
#    node = child.marc.first_occurance("852", "c")
#    node.content = shelfmark
#    child.save!
#    maintenance.logger.info("#{maintenance.host}: #{child.id} shelfmark '[no indication]' -> '#{shelfmark}'")
#  end
#}

maintenance.execute process

