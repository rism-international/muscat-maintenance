# encoding: UTF-8
#
puts "##################################################################################################"
puts "##################      ISSUE: Changing different values with ICCU   #############################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
hash = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[0].to_i
  _260a = row[1]
  _260c = row[2]
  _300a = row[3]
  _300c = row[4]
  _593a = row[5]
  _657a = row[7]
  hash[id] = {_260a: _260a, _260c: _260c, _300a: _300a, _300c: _300c, _593a: _593a, _657a: _657a}
end

sources = Source.where(:id => hash.keys)
maintenance = Muscat::Maintenance.new(sources)
#PaperTrail.request.disable_model(Source)
 
process = lambda { |record|
  _260a = hash[record.id][:_260a]
  _260c = hash[record.id][:_260c]
  _300a = hash[record.id][:_300a]
  _300c = hash[record.id][:_300c]
  _593a = hash[record.id][:_593a]
  _657a = hash[record.id][:_657a]
  modified = false
  record.suppress_reindex

  record_type = record.record_type
  marc = MarcSource.new(record.marc_source)
  marc.load_source(false)
  
  marc.each_by_tag("260") do |n|
    n.destroy_yourself
  end
  marc.each_by_tag("300") do |n|
    n.destroy_yourself
  end
  marc.each_by_tag("593") do |n|
    n.destroy_yourself
  end
  marc.each_by_tag("657") do |n|
    n.destroy_yourself
  end

  if _260a || _260c
    new_node = MarcNode.new(Source, "260", "", "##")
    ip = marc.get_insert_position("260")
    new_node.add(MarcNode.new(Source, "a", "#{_260a}", nil)) if _260a
    new_node.add(MarcNode.new(Source, "c", "#{_260c}", nil)) if _260c
    new_node.add(MarcNode.new(Source, "8", "01", nil))
    marc.root.children.insert(ip, new_node)
    modified = true
  end

  if _300a || _300c
    new_node = MarcNode.new(Source, "300", "", "##")
    ip = marc.get_insert_position("300")
    new_node.add(MarcNode.new(Source, "a", "#{_300a}", nil)) if _300a
    new_node.add(MarcNode.new(Source, "c", "#{_300c}", nil)) if _300c
    new_node.add(MarcNode.new(Source, "8", "01", nil))
    marc.root.children.insert(ip, new_node)
    modified = true
  end

  if _593a
    new_node = MarcNode.new(Source, "593", "", "##")
    ip = marc.get_insert_position("593")
    new_node.add(MarcNode.new(Source, "a", "#{_593a}", nil)) if _593a
    new_node.add(MarcNode.new(Source, "8", "01", nil))
    marc.root.children.insert(ip, new_node)
    modified = true
  end

  if _657a
    new_node = MarcNode.new(Source, "657", "", "##")
    ip = marc.get_insert_position("657")
    new_node.add(MarcNode.new(Source, "a", "#{_657a}", nil)) if _657a
    marc.root.children.insert(ip, new_node)
    modified = true
  end

  if modified
    import_marc = MarcSource.new(marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 260a '#{_260a}'") if _260a
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 260c '#{_260c}'") if _260c
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 300a '#{_300a}'") if _300a
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 300c '#{_300c}'") if _300c
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 593a '#{_593a}'") if _593a
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 657a '#{_657a}'") if _657a
    rescue 
      maintenance.logger.info("#{maintenance.host}: Sistina ERROR #{record.id} added genre '#{genres}' (frozen string)")
    end
  end

}

maintenance.execute process



