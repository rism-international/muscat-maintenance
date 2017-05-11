# encoding: UTF-8
puts "##################################################################################################"
puts "################### ISSUE #26: Add missing 260a without normalized version   #####################"
puts "###########################     Expected collection size: 2.348            #######################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"
TAG="260"
CODE="a"
yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  id = "%09d" % record.id
  layers = yaml[id]
  marc = record.marc
  nodes = [] 
  nodes_layers = []
  marc.each_by_tag(TAG) {|t| nodes << t}
  nodes.each do |n|
    nodes_layers << n.fetch_first_by_tag("8").content rescue nil
  end
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
 ###          |  |  |  |  then add content with import content              ###
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
    if !nodes_layers.include?(k) # CASE01
      new_260 = MarcNode.new(Source, TAG, "", "##")
      ip = marc.get_insert_position(TAG)
      new_260.add(MarcNode.new(Source, CODE, "#{content}", nil))
      new_260.add(MarcNode.new(Source, "8", "#{k}", nil))
      marc.root.children.insert(ip, new_260)
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} CASE01 CREATE tag 260$a[#{k}]: '#{content}'")
      modified = true
    else
      nodes.each do |n|
        if n.fetch_first_by_tag("8").content == k # CASE02
          existing_node = n.fetch_first_by_tag(CODE)
          if existing_node # CASE03
            existing_content = existing_node.content rescue ""
            if content != existing_content # CASE 04
              if record.versions.empty? # CASE05
                existing_node.content = "#{existing_content}; #{content}"
                maintenance.logger.info("#{maintenance.host}: Source ##{record.id} CASE05 ADDED existing tag 260$a[#{k}]: '#{existing_content}' -> '#{content}'")
                modified = true
              else # CASE06
                if content.start_with?(existing_content) # CASE07
                  existing_node.content = content
                  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} CASE07 OVERWRITE existing tag 260$a[#{k}]: '#{existing_content}' -> '#{content}'")
                  modified = true
                else # CASE08
                  maintenance.logger.warn("#{maintenance.host}: Source ##{record.id} CASE08 NOT OVERWRITE existing tag newer 260$a[#{k}]: '#{existing_content}' remains, not '#{content}'")
                end
              end
            else # CASE 09
              # Do nothing because import content == existing content
            end
          else # CASE10
            n.add(MarcNode.new(Source, CODE, "#{content}", nil))
            n.sort_alphabetically
            maintenance.logger.info("#{maintenance.host}: Source ##{record.id} CASE10 CREATE subfield 260$a[#{k}]: '#{content}'")
            modified = true 
          end
        end
      end
    end
  end
  record.save if modified
}

maintenance.execute process

