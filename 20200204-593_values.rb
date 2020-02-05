# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Cleanup 593 values                        #######################"
puts "############################   Expected collection size: 150    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200204-593_values.yml")
ids = []

terms.keys.each do |t|
  sx = Source.solr_search do
    with("593a_filter", t)
  end
  sx.hits.each do |hit|
    ids << hit.result.id
  end
end

sources = Source.where(:id => ids)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  previous_term = ""
  new_term = ""
  marc.each_by_tag("593") do |n|
    sfa = n.fetch_first_by_tag("a")
    previous_term = sfa.content
    new_term = terms[previous_term]
    if new_term
      #puts "#{previous_term} <==> #{new_term}"
      sfa.content = new_term
      modified = true
    else
      #puts previous_term.yellow
      next
    end
  end
  if modified
    record.save
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 593: '#{previous_term.yellow}' => '#{new_term.green}'")
  end

}

maintenance.execute process
