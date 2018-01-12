# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Change Siglum         ##################################"
puts "############################   Expected collection size: 512    ##################################"
puts "########################## Change siglum from N-Ou to N-Onm      #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

old_siglum = "N-Ou" 
new_siglum = "N-Onm"
new_institution = Institution.where(siglum: new_siglum).take

sx = Source.where(lib_siglum: old_siglum)
hx = Holding.where(lib_siglum: old_siglum)
sources = sx + hx

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
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
  record.save if modified
  if record.is_a?(Holding)
    record.source.index!
  else
    record.index!
  end
}

maintenance.execute process

