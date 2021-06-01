# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Add siglum from collection parent    ################################"
puts "#########################   Expected collection size: ca.15.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.all
  #where(wf_owner: 268).where(record_type: 2).where(lib_siglum: "")

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  #next unless record.source_id
  if record.marc.root.fetch_first_by_tag("852")
    next
  end
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  #parent_siglum = Institution.where(siglum: Source.find(record.source_id).lib_siglum).take
  #next unless parent_siglum

  new_852 = MarcNode.new(Source, "852", "", "##")
  ip = new_marc.get_insert_position("852")
  new_852.add(MarcNode.new(Source, "x", "51000237", nil))
  new_852.sort_alphabetically
  new_marc.root.children.insert(ip, new_852)

  import_marc = MarcSource.new(new_marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  record.marc = import_marc
  record.record_type = record_type
  record.save!
  #maintenance.logger.info("#{maintenance.host}: Source ##{record.id} get siglum #{parent_siglum.id}")
}

maintenance.execute process
