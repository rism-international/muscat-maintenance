# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Set arr in 240$o                          #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(:wf_owner => 327)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("700") do |n|
    n.each_by_tag("4") do |sf|
      if sf.content == 'arr'
        modified = true
      end
    end
  end

  if modified
    tag = marc.first_occurance("240")
    tag.add(MarcNode.new(Source, "o", "arr", nil))
    tag.sort_alphabetically
    record.save
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 240$o: added 'arr'")
  end

}

maintenance.execute process
