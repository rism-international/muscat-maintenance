# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change fmo to provenance                  ##########################"
puts "#########################   Expected collection size: ca. 2000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

siglum = "PL-OPcbje"
sources = Source.where(lib_siglum: siglum)#.where(record_type: 1) + Source.where(lib_siglum: siglum).where(record_type: 2).where(source_id: nil) + Holding.where(lib_siglum: siglum)
maintenance = Muscat::Maintenance.new(sources)
provenance = Institution.find(30006024)

process = lambda { |record|
  klass = record.class.to_s == "Source" ? "Source" : "Holding"
  record_type = record.record_type if klass == "Source"
  has_tag = false
  marc = record.marc
  marc.each_by_tag("710") do |tag|
    zero_tag = tag.fetch_first_by_tag("0")
    if zero_tag.content == provenance.id
      has_tag = true
    end
  end
  next if has_tag

  new_marc = "Marc#{klass}".constantize.new(record.marc_source)
  new_marc.load_source(false)
  ip = new_marc.get_insert_position("710")
  new_710 = MarcNode.new("#{klass}".constantize, "710", "", "1#")
  new_710.add(MarcNode.new("#{klass}".constantize, "0", provenance.id, nil))
  new_710.add(MarcNode.new("#{klass}".constantize, "4", "fmo", nil))
  new_marc.root.children.insert(ip, new_710)
  
  import_marc = "Marc#{klass}".constantize.new(new_marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  record.marc = import_marc
  record.record_type = record_type if klass == "Source"
  maintenance.logger.info("#{maintenance.host}: #{klass} ##{record.id} $710 added fmo #{siglum}.")
  record.save!
}

maintenance.execute process

