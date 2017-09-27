# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Move 340$a to sf $d   ##################################"
puts "############################   Expected collection size: 700    ##################################"
puts "##################################################################################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

# Because only 340$d was indexed we have to go over fulltext search
sources = Source.where('marc_source like ?', '%=340  #%')

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("340") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if a_tag.content
      tag.add(MarcNode.new(Source, "d", "#{a_tag.content}", nil))
      a_tag.destroy_yourself
      tag.sort_alphabetically
      maintenance.logger.info("#{maintenance.host}: Source #{record.id} moved '#{a_tag.content}' to sf $d")
      modified = true
    end
  end
  record.save if modified
}

maintenance.execute process
