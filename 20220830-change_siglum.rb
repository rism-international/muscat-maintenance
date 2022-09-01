# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Change Siglum         ##################################"
puts "############################   Expected collection size: 2.000  ##################################"
puts "######################## Change siglum from NL-DHgm to NL-DHnmi  #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

old_siglum = "NL-DHgm" 
new_siglum = "NL-DHnmi"
new_institution = Institution.where(siglum: new_siglum).take

sx = Source.where(lib_siglum: old_siglum)
hx = Holding.where(lib_siglum: old_siglum)
sources = sx + hx

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
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

  if modified
    import_marc = marc_class.new(marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type if record_type
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} Siglum NL-DHgm -> NL-DHnmi")
    rescue 
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id} Siglum NL-DHgm -> NL-DHnmi")
    end
  end

}

maintenance.execute process

puts "INDEXING"
Sunspot.index(sources)
Sunspot.commit
