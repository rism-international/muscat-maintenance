# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE #16: Add missing 260c   ##################################"
puts "############################   Expected collection size: 7.068  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  kallisto = yaml[record.id.to_s]
  layers = kallisto.inject(:merge)
  marc = record.marc
  nodes = [] 
  nodes_keys = []
  marc.each_by_tag("260") {|t| nodes << t}
  nodes.each do |n|
    nodes_keys << n.fetch_first_by_tag("8").content rescue nil
  end
 
  layers.each do |k,v|

    # If the material layer doesn't exist: create a new datafield with this layer
    if !nodes_keys.include?(k)
      new_260 = MarcNode.new(Source, "260", "", "##")
      ip = marc.get_insert_position("260")
      new_260.add(MarcNode.new(Source, "c", "#{v}", nil))
      new_260.add(MarcNode.new(Source, "8", "#{k}", nil))
      marc.root.children.insert(ip, new_260)
      modified = true
    
    # If the materials layer exist and subfield $c not: add the subfield
    else
      nodes.each do |n|
        if n.fetch_first_by_tag("8").content == k
          n.add(MarcNode.new(Source, "c", "#{v}", nil)) if !n.fetch_first_by_tag("c")
          modified = true
        end
      end
    end
  end
  #ecord.save if modified
  #aintenance.logger.info("#{maintenance.host}: Source ##{record.id} added missing 260$c.")
}

maintenance.execute process
