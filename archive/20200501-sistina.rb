# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Add 040 and 980 to sistina           ##########################"
puts "#########################   Expected collection size: ca. 3000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 315)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.suppress_reindex

  unless record.marc.root.fetch_first_by_tag("040")
    new_040 = MarcNode.new(Source, "040", "", "##")
    ip = record.marc.get_insert_position("040")
    new_040.add(MarcNode.new(Source, "b", "ger", nil))
    record.marc.root.children.insert(ip, new_040)
  end

  new_980 = MarcNode.new(Source, "980", "", "##")
  ip = record.marc.get_insert_position("980")
  new_980.add(MarcNode.new(Source, "a", "import", nil))
  record.marc.root.children.insert(ip, new_980)
  maintenance.logger.info("#{maintenance.host}: Added admin fields to #{record.id}")
  record.save

}

maintenance.execute process
