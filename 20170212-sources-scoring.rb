# encoding: UTF-8
puts "##################################################################################################"
puts "########################  ISSUE #12: Add and change comment on scoring   #########################"
puts "############################   Expected collection size: 3.907  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  id = "%09d" % record.id
  kallisto = yaml[id]
  marc = record.marc
 
  # Add tag with missing socring on comment
  if kallisto['add']
    new_500 = MarcNode.new(Source, "500", "", "##")
    ip = marc.get_insert_position("500")
    new_500.add(MarcNode.new(Source, "a", "Comment on scoring: #{kallisto['add']}", nil))
    marc.root.children.insert(ip, new_500)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} add tag 500$a with content 'Commment on scoring: #{kallisto['add']}'")
    modified = true
  end

  # Remove material layer subfield $8 if comment on scoring
  if kallisto['remove_material']
    existent_tags = []
    marc.each_by_tag("500") {|t| existent_tags << t}
    existent_tags.each do |tag|
      if tag.fetch_first_by_tag("a").content.start_with?("Comment on scoring")
        r_node = tag.fetch_first_by_tag("8")
        r_node.destroy_yourself
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} removed subfield $8 with 'Comment on scoring'")
        modified = true
      end
    end
  end
  record.save if modified
}

maintenance.execute process
