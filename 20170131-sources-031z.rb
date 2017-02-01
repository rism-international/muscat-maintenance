# encoding: UTF-8
puts "##################################################################################################"
puts "############# ISSUE #24: Remove leading 'Scoring: ' in 031$z  ####################################"
puts "#####################   Expected collection size: 17.281  ########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml)



maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("031") do |tag|
    a_tag = tag.fetch_first_by_tag("z")
    if a_tag && a_tag.content.start_with?("Scoring: ")
      a_tag.content = a_tag.content.gsub("Scoring: ", "")
        modified = true
    end
  end

  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} $031z removed leading 'Scoring'.")
}

maintenance.execute process
