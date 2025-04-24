# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE : Add Provenance        ##################################"
puts "############################   Expected collection size: 9.000  ##################################"
puts "########################## Adding provenance for BSB             #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

bem = "BSB-Provenienz: Schott-Archiv / Herstellungsarchiv, erworben 2014"

sx = Source.where("shelf_mark like ?", "Mus.Schott.Ha%")
hx = Holding.where("shelf_mark like ?", "Mus.Schott.Ha%")
sources = sx + hx

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  klass = record.class.to_s == "Source" ? "Source" : "Holding"
  record_type = record.record_type if klass == "Source"
  modified = false
  has_tag = false

  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.each_by_tag("561") do |tag|
    zero_tag = tag.fetch_first_by_tag("a")
    if zero_tag.content == bem
      has_tag = true
    end
  end
  next if has_tag

  new_marc = "Marc#{klass}".constantize.new(record.marc_source)
  new_marc.load_source(false)
  ip = new_marc.get_insert_position("561")
  new_561 = MarcNode.new("#{klass}".constantize, "561", "", "2#")
  new_561.add(MarcNode.new("#{klass}".constantize, "a", bem, nil))
  new_marc.root.children.insert(ip, new_561)
  modified = true

  if modified
    import_marc = "Marc#{klass}".constantize.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type if klass == "Source"
    maintenance.logger.info("#{maintenance.host}: #{klass} ##{record.id} $561a changed.")
    record.save!

  end
}

maintenance.execute process

puts "INDEXING"
Sunspot.index(sources)
Sunspot.commit
