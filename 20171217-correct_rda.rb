# encoding: UTF-8
puts "##################################################################################################"
puts "###################### Correct rda indicator with VeMo records      ##############################"
puts "#####################   Expected collection size: 10.046  ########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => (456082231..457000000)).where('updated_at < ?', Time.now - 1.day)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("730") do |tag|
    g_tag = tag.fetch_first_by_tag("g")
    g_tag.content = "RDA"
    modified = true
  end
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: #{record.id}: 730$g changed to RDA")
}

maintenance.execute process
