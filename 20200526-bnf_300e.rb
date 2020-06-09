# encoding: UTF-8
puts "##################################################################################################"
puts "################                ISSUE tasks: Drop 300e values              #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(:wf_owner => 327)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("300") do |n|
    n.each_by_tag("e") do |sf|
      sf.destroy_yourself
      modified = true
    end
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} deleted 300$e")
    record.save
  end
}

maintenance.execute process
