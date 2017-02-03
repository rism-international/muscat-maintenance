# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE #13: Add missing 260a   ##################################"
puts "#################  Expected collection size: 18.149, to update: ca. 9.418  #######################"
puts "##################################################################################################"
puts ""

 ##########################################################################
 ###                        PSEUDOCODE                                  ###
 ### CASES:                                                             ###
 ###  CASE1: tag 260 doesn't exist at all:                              ###
 ###           -> add tag 260                                           ###
 ###  CASE2: tag 260 does exist                                         ###
 ###  CASE3:   tag260 layer doesn't exist:                              ###
 ###             -> add tag260 with new layer                           ###
 ###  CASE4:   tag260 layer does exist:                                 ###
 ###  CASE5:     subfield $a doesn't exist:                             ###
 ###               -> add subfield $a                                   ###
 ###  CASE6:     subfield a exist:                                      ###
 ###  CASE7:       $a content == import content:                        ###
 ###                 -> do nothing                                      ###
 ###  CASE8:       $a content <> import content:                        ###
 ###  CASE9:         record hasn't changed                              ###
 ###                   -> Overwrite content with import content         ###
 ###  CASE10:        record has recently changed                        ###
 ###  CASE11:          subfield has changed                             ###
 ###                     -> Do nothing (only with about 10 records)     ###  
 ###  CASE12:          subfield starts with import content              ###
 ###                     -> Overwrite content with import content       ###
 ##########################################################################

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  id = "%09d" % record.id
  layers = yaml[id]
  marc = record.marc
  nodes = [] 
  nodes_keys = []
  marc.each_by_tag("260") {|t| nodes << t}
  nodes.each do |n|
    nodes_keys << n.fetch_first_by_tag("8").content rescue nil
  end
  #puts "#{layers.keys.sort.to_s rescue ''} <---> #{nodes_keys.sort.to_s rescue ''}"
  layer_pool  = {}
  layers.each do |l|
    k = l.keys.first
    if !layer_pool[k]
      layer_pool[k] = [l[k]]
    else
      layer_pool[k] << l[k]
    end
  end
 
  layer_pool.each do |k,v|
    content = v.join("; ")
    # If the material layer doesn't exist: create a new datafield with this layer
    # CASE1
    # CASE3
    if !nodes_keys.include?(k)
      new_260 = MarcNode.new(Source, "260", "", "##")
      ip = marc.get_insert_position("260")
      new_260.add(MarcNode.new(Source, "c", "#{content}", nil))
      new_260.add(MarcNode.new(Source, "8", "#{k}", nil))
      marc.root.children.insert(ip, new_260) #,CASE1, CASE2
      modified = true
    
    # If the materials layer exist and subfield $c not: add the subfield
    # CASE2
    else
      nodes.each do |n|
        # CASE4
        if n.fetch_first_by_tag("8").content == k
          existing_node = n.fetch_first_by_tag("a")
          # CASE6
          if existing_node
            existing_content = existing_node.content rescue ""
            # CASE8
            if content != existing_content
              # CASE9
              if record.versions.empty?
                existing_node.content = content
                modified = true
              # CASE10
              else
                # CASE12
                if content.start_with?(existing_content)
                  existing_node.content = content
                  modified = true
                # CASE11
                else
                  # Do nothing not to overwrite user changed content
                end
              end
            # CASE7
            else
              # do nothing because import content == existing content
            end
          # CASE5
          else
            #Add subfield if not exist
            n.add(MarcNode.new(Source, "a", "#{content}", nil))
            n.sort_alphabetically
            modified = true 
          end
        end
      end
    end
  end
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added missing 260$c.")
}

maintenance.execute process
