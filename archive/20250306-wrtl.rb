# encoding: UTF-8
puts "##################################################################################################"
puts "##########################     ISSUE : Add Provenance to D-WRtl  #################################"
puts "############################   Expected collection size: 870    ##################################"
puts "##########################                                       #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

prov = Institution.find(30008580)
new_siglum = Institution.where(siglum: "D-WRz").take

hx = Holding.where(lib_siglum: "D-WRtl")
sources = hx

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  klass = record.class.to_s == "Source" ? "Source" : "Holding"
  record_type = record.record_type if klass == "Source"
  modified = false
  has_tag = false

  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc = "Marc#{klass}".constantize.new(record.marc_source)
  new_marc.load_source(false)
  ip = new_marc.get_insert_position("710")
  new_710 = MarcNode.new("#{klass}".constantize, "710", "", "2#")
  new_710.add(MarcNode.new("#{klass}".constantize, "0", prov.id, nil))
  new_710.add(MarcNode.new("#{klass}".constantize, "4", "fmo", nil))
  new_marc.root.children.insert(ip, new_710)
  modified = true


  new_marc.each_by_tag("852") do |tag|
    sf = tag.fetch_first_by_tag("x")
    if sf && sf.content
      sf.content = new_siglum.id
    end
  end

  if modified
    import_marc = "Marc#{klass}".constantize.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type if klass == "Source"
    maintenance.logger.info("#{maintenance.host}: #{klass} #{record.source_id} holding #{record.id} changed.")
    record.save!

  end

}

maintenance.execute process
