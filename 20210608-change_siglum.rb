# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Change Siglum         ##################################"
puts "############################   Expected collection size: 9.000  ##################################"
puts "########################## Change siglum from D-DO to D-KA       #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

old_siglum = "D-DO" 
new_siglum = "D-KA"
new_institution = Institution.where(siglum: new_siglum).take
provenance_id = '30035148'
former = "Fürstlich Fürstenbergische Hofbibliothek, Donaueschingen"

sx = Source.where(lib_siglum: old_siglum)
hx = Holding.where(lib_siglum: old_siglum)
sources = sx + hx

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  has_710 = false
  has_561 = false
  record_class = record.class.name.demodulize.classify.constantize
  marc_class = "Marc#{record_class}".demodulize.classify.constantize
  record_type = record.record_type rescue nil
  marc = marc_class.new(record.marc_source)
  marc.load_source(false)
 
  marc.each_by_tag("852") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if a_tag.content == old_siglum
      tag.foreign_object = new_institution
      x = tag.fetch_first_by_tag("x")
      xnode = x.deep_copy
      x.destroy_yourself
      xnode.foreign_object=new_institution
      xnode.content = new_institution.id
      tag.add(xnode)
      tag.resolve_externals
      modified = true
    end
    record.lib_siglum = new_siglum
  end
  
  marc.each_by_tag("710") do |tag|
    a_tag = tag.fetch_first_by_tag("0")
    if a_tag and a_tag.content == provenance_id
      has_710 = true
    end
  end

  unless has_710
    ip = marc.get_insert_position("710")
    new_710 = MarcNode.new(record_class, "710", "", "2#")
    new_710.add(MarcNode.new(record_class, "0", provenance_id, nil))
    new_710.add(MarcNode.new(record_class, "4", "fmo", nil))
    marc.root.children.insert(ip, new_710)
  end

  marc.each_by_tag("561") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if a_tag and a_tag.content == former
      has_561 = true
    end
  end

  unless has_561
    ip = marc.get_insert_position("561")
    new_561 = MarcNode.new(record_class, "561", "", "2#")
    new_561.add(MarcNode.new(record_class, "a", former, nil))
    marc.root.children.insert(ip, new_710)
  end

  if modified
    import_marc = marc_class.new(marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type if record_type
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} Siglum D-DO -> D-KA")
    rescue 
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id} Siglum D-DO -> D-KA")
    end
  end

  #if record.is_a?(Holding)
    #record.source.index!
  #else
  #  record.index!
  #end
}

maintenance.execute process

puts "INDEXING"
Sunspot.index(sources)
Sunspot.commit
