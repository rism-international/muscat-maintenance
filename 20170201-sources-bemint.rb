# encoding: UTF-8
puts "##################################################################################################"
puts "############# ISSUE #11: Move internal remarks from false 500 to 599  ############################"
puts "#####################   Expected collection size: 3.565  #########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  list_bemints = yaml[record.id.to_s]
  modified = false
  marc = record.marc
  tags = []
  marc.each_by_tag("500") {|t| tags << t}
  
  tags.each do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if list_bemints.include?(a_tag.content)
      modified = true
      new_tag = tag.deep_copy
      new_tag.tag = "599"
      ip = marc.get_insert_position("599")
      marc.root.add_at(new_tag, ip)
      tag.destroy_yourself
    end
  end
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} bemint moved to 599.")
}

maintenance.execute process
