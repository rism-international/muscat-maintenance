# encoding: UTF-8
puts "##################################################################################################"
puts "########################  ISSUE : Add shelfmark to moravian     ##################################"
puts "#######################   Expected collection size: ca.3.500    ##################################"
puts "########################           Adding missing shelfmark      #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  shelfmark = yaml[record.id]
  marc.each_by_tag("852") do |tag|
    next if tag.fetch_first_by_tag("c")
    if shelfmark
      tag.add(MarcNode.new(Source, "c", "#{shelfmark}", nil))
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} with moravian shelfmark '#{shelfmark}'")
      modified = true
    end
  end
  record.save if modified
}

maintenance.execute process

