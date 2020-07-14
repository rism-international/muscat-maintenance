# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Change 650 with Sistina                   #######################"
puts "############################   Expected collection size: 3.300  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml

sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|

  modified = false
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.root.fetch_all_by_tag("650").each do |e|
    e.destroy_yourself
  end
  #FIXME only the last tag is destroyed by the following
=begin
  new_marc.each_by_tag("650") do |e|
    e.destroy_yourself
  end
=end

  genres = yaml[record.id]

  genres.split(";").each do |genre|
    new_650 = MarcNode.new(Source, "650", "", "##")
    ip = new_marc.get_insert_position("650")
    new_650.add(MarcNode.new(Source, "a", "#{genre.strip}", nil))
    new_650.sort_alphabetically
    new_marc.root.children.insert(ip, new_650)
    modified = true
  end

  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: Sistina #{record.id} added genre '#{genres}'")
    rescue 
      maintenance.logger.info("#{maintenance.host}: Sistina ERROR #{record.id} added genre '#{genres}' (frozen string)")
    end
  end

}

maintenance.execute process
