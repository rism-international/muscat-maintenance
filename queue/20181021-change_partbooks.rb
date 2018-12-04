# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Change partbooks etc. to parts       ################################"
puts "##########################   Expected collection size: ca.1800  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sx = Source.solr_search do 
  fulltext "-choir +*book", :fields => '300a' 
  paginate :page => 1, :per_page => 999999
end
sources = sx.results
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("300") do |tag|
    tag.each_by_tag("a") do |subtag|
      previous_content = subtag.content
      if previous_content.include?("partbook") || previous_content.include?("part-book") || previous_content.include?("part book")
        subtag.content = subtag.content.sub("partbook", "part").sub("part-book", "part").sub("part book", "part")
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} changed 300$a '#{previous_content}' -> '#{subtag.content}'")
        modified = true
      end
    end
  end
  if modified
    record.save
  end
}

maintenance.execute process
