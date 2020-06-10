# encoding: UTF-8
puts "##################################################################################################"
puts "###########################      ISSUE tasks: Remove 245a pipes            #######################"
puts "############################   Expected collection size: 1.000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(:wf_owner => 327)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  genres = []
  marc.each_by_tag("650") do |tag|
    tag.each_by_tag("0") do |sf|
      if genres.include?(sf.content)
        tag.destroy_yourself
        modified = true
      else
        genres << sf.content
      end
    end
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 650$0: deleted duplicate entry")
    record.save
  end
}

maintenance.execute process
