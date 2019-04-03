# encoding: UTF-8
#
puts "##################################################################################################"
puts "#############################  ISSUE: Change 730$g to 'ICCU'      ################################"
puts "##########################   Expected collection size: 10       ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source REGEXP '=730[^\n]*\[[.$.]]a'")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("730") do |tag|
    subfields = tag.fetch_all_by_tag("g")

    if subfields.empty?
      tag.add(MarcNode.new(Source, "g", "ICCU", nil))
      tag.sort_alphabetically
      modified = true
    else
      subfields.first.content = "ICCU"
      modified = true
    end
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added $g ICCU") if modified
    record.save
  end
}

maintenance.execute process
