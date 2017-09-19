# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Change Siglum         ##################################"
puts "############################   Expected collection size: 927    ##################################"
puts "######## Change siglum to D-Bda and transfer shelfmark to $d; insert new shelfmark    ############"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

#aml = Muscat::Maintenance.yaml
sources = Source.where(:composer => 'Schoendlinger, Anton').where(:lib_siglum => 'D-BGLidmo')

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("852") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if a_tag.content == 'D-BGLidmo'
      c_tag = tag.fetch_first_by_tag("c")
      tag.add(MarcNode.new(Source, "d", "#{c_tag.content}", nil))
      c_tag.content = "Schoendlinger"
      tag.foreign_object = Institution.find(30003253)
      x = tag.fetch_first_by_tag("x")
      xnode = x.deep_copy
      x.destroy_yourself
      xnode.foreign_object=Institution.find(30003253)
      xnode.content = 30003253
      tag.add(xnode)
      tag.resolve_externals
      modified = true
    end
  end
  record.save if modified
}

maintenance.execute process
