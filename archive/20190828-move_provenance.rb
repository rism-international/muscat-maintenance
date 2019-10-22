# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Move siglum to provenance with folders    ##########################"
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

res.each do |siglum, sx|
  sources = Source.where(id: sx)
  maintenance = Muscat::Maintenance.new(sources)
  provenance = Institution.where('binary siglum = ?', siglum).take
  
  process = lambda { |record|
    holdings = record.holdings
    if holdings.empty?
      record_type = record.record_type
      new_marc = MarcSource.new(record.marc_source)
      new_marc.load_source(false)
      ip = new_marc.get_insert_position("710")
      new_710 = MarcNode.new(Source, "710", "", "2#")
      new_710.add(MarcNode.new(Source, "0", provenance.id, nil))
      new_710.add(MarcNode.new(Source, "4", "fmo", nil))
      new_marc.root.children.insert(ip, new_710)
      import_marc = MarcSource.new(new_marc.to_marc)
      import_marc.load_source(false)
      import_marc.import
      record.marc = import_marc
      record.record_type = record_type
      record.save!
    else
      holdings.each do |holding|
        if holding.lib_siglum == siglum
          new_marc = MarcHolding.new(holding.marc_source)
          new_marc.load_source(false)
          ip = new_marc.get_insert_position("710")
          new_710 = MarcNode.new(Holding, "710", "", "2#")
          new_710.add(MarcNode.new(Holding, "0", provenance.id, nil))
          new_710.add(MarcNode.new(Holding, "4", "fmo", nil))
          new_marc.root.children.insert(ip, new_710)
          import_marc = MarcHolding.new(new_marc.to_marc)
          import_marc.load_source(false)
          import_marc.import
          holding.marc = import_marc
          #record.record_type = record_type
          holding.save!
        end
      end


    end
  }

  maintenance.execute process
end

