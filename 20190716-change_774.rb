# encoding: UTF-8
#
puts "##################################################################################################"
puts "#################    ISSUE: Change 774$w and $4                         ##########################"
puts "#########################   Expected collection size: 70        ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(id: Holding.where.not(collection_id: nil).pluck(:collection_id).uniq)
#sources = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("774") do |t|
      t.each_by_tag("4") do |tn|
        holding_node = t.fetch_first_by_tag("w")
        holding_id = holding_node.content
        source_id = Holding.find(holding_id).source_id rescue next
        holding_node.content = source_id
        tn.content = "holding #{holding_id}"
        modified = true
      end
    end
 

  maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} changed 774")
  modified = true
  record.save if modified

}

maintenance.execute process
