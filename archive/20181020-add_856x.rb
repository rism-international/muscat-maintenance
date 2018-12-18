# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Add digitalization marker in 856$x   ################################"
puts "##########################   Expected collection size: 25.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sx = Source.solr_search do 
  fulltext "digit", :fields => '856z' 
  paginate :page => 1, :per_page => 999999
end
sources = sx.results
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("856") do |tag|
    next if tag.fetch_first_by_tag("x")
    tag.each_by_tag("z") do |subtag|
      if subtag.content and subtag.content =~ /^Digit|[Dd]igitized/
        tag.add(MarcNode.new(Source, "x", "Digitalization", nil))
        tag.sort_alphabetically
        modified = true
      else
        tag.add(MarcNode.new(Source, "x", "Other", nil))
        tag.sort_alphabetically
        modified = true
      end
    end
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added $x Digitizalization") if modified
    record.save
  end
}

maintenance.execute process
