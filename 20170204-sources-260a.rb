# encoding: UTF-8
puts "##################################################################################################"
puts "################################  ISSUE #13: Add missing 260a   ##################################"
puts "#################  Expected collection size: 18.149, to update: ca. 9.418  #######################"
puts "##################################################################################################"
puts ""
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
 
 ##############################################################################
 ###                          ## PSEUDOCODE ##                              ###
 ###                          ################                              ###
 ###                                                                        ###
 ###  CASE01: if tag 260 doesn't exist or hasn't the same layer             ###
 ###          |  then Add tag 260 with layer                                ###
 ###  CASE02: if tag 260 same layer does exist                              ###
 ###  CASE03: |  if subfield $a exist                                       ###
 ###  CASE04: |  |  if existing content <> import content                   ###
 ###  CASE05: |  |  |  if record hasn't changed                             ###
 ###          |  |  |  |  then Overwrite content with import content        ###
 ###  CASE06: |  |  |  else record has recently changed                     ###
 ###  CASE07: |  |  |  |  if existing content starts with import content    ###
 ###          |  |  |  |  |  then Overwrite content with import content     ###
 ###  CASE08: |  |  |  |  else subfield $a has somehow changed              ###
 ###          |  |  |  |  |  then Do nothing and Log (only ca. 10 records)  ###  
 ###  CASE09: |  |  else existing content == import content                 ###
 ###          |  |  |  then Do nothing                                      ###
 ###  CASE10: |  else subfield $a doesn't exist:                            ###
 ###          |  |  then Add subfield $a                                    ###
 ###                                                                        ###
 ##############################################################################


  layer_pool.each do |k,v|
    content = v.join("; ")
    # CASE01
    if !nodes_keys.include?(k)
      new_260 = MarcNode.new(Source, "260", "", "##")
      ip = marc.get_insert_position("260")
      new_260.add(MarcNode.new(Source, "c", "#{content}", nil))
      new_260.add(MarcNode.new(Source, "8", "#{k}", nil))
      marc.root.children.insert(ip, new_260) #,CASE1, CASE2
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} tag 260$a #{k} added '#{content}'")
      modified = true
    # CASE2
    else
      nodes.each do |n|
        # CASE02
        if n.fetch_first_by_tag("8").content == k
          existing_node = n.fetch_first_by_tag("a")
          # CASE03
          if existing_node
            existing_content = existing_node.content rescue ""
            # CASE04
            if content != existing_content
              # CASE05
              if record.versions.empty?
                existing_node.content = content
                maintenance.logger.info("#{maintenance.host}: Source ##{record.id} content '#{existing_content}' changed to '#{content}'")
                modified = true
              else
                # CASE07
                if content.start_with?(existing_content)
                  existing_node.content = content
                  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} content '#{existing_content}' starting as and changed to '#{content}'")
                  modified = true
                # CASE08
                else
                  # Do nothing and log
                  maintenance.logger.warn("#{maintenance.host}: Source ##{record.id} has newer content '#{existing_content}' then '#{content}'")
                end
              end
            # CASE09
            else
              # Do nothing because import content == existing content
            end
          # CASE10
          else
            #Add subfield if not exist
            n.add(MarcNode.new(Source, "a", "#{content}", nil))
            n.sort_alphabetically
            maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added $a '#{content}'")
            modified = true 
          end
        end
      end
    end
  end
  record.save if modified
}

maintenance.execute process
