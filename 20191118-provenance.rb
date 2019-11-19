# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change fmo to provenance with folders     ##########################"
puts "#########################   Expected collection size: ca. 2000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

res = {}
folders = Folder.where(id: (297..302))
folders.each do |f|
  name = f.name.split(" ").first
  idx = []
  f.folder_items.each do |i|
    idx << i.item_id    
  end
  res[name] = idx
end
siglum_id = 30006485

res.each do |siglum, sx|
  sources = Source.where(id: sx)
  maintenance = Muscat::Maintenance.new(sources)
  provenance = Institution.where('binary siglum = ?', siglum).take
  
  process = lambda { |record|
    modified = false
    holdings = record.holdings
    if holdings.empty?
      marc = record.marc
      marc.each_by_tag("710") do |tag|
        zero_tag = tag.fetch_first_by_tag("0")
        if zero_tag.content == siglum_id
          tag.foreign_object = provenance
          x = tag.fetch_first_by_tag("0")
          xnode = x.deep_copy
          x.destroy_yourself
          xnode.foreign_object=provenance
          xnode.content = provenance.id
          tag.add(xnode)
          tag.resolve_externals
          modified = true
        end
        record.save if modified
        binding.pry
      end

    else
      holdings.each do |holding|
        marc = holding.marc
        marc.each_by_tag("710") do |tag|
          zero_tag = tag.fetch_first_by_tag("0")
          if zero_tag.content == siglum_id
            tag.foreign_object = provenance
            x = tag.fetch_first_by_tag("0")
            xnode = x.deep_copy
            x.destroy_yourself
            xnode.foreign_object=provenance
            xnode.content = provenance.id
            tag.add(xnode)
            tag.resolve_externals
            modified = true
          end
        end
        holding.save if modified
        binding.pry
      end
    end
  }

  maintenance.execute process
end

