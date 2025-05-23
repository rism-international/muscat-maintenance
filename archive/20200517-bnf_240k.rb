# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Move 240k                                 #######################"
puts "############################   Expected collection size: 200    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200517-bnf_240k.yml")

sources = Source.where(:id => terms)#.where('updated_at < ?', Time.parse("2019-12-22"))
maintenance = Muscat::Maintenance.new(sources)

def same_tag_in_versions?(record, node)
  return true if record.versions.size == 0
  res = []
  record.versions.order(:created_at).each do |v|
    ver = []
    marc = MarcSource.new(v.reify.marc_source)
    marc.load_source(false)
    tag = node.parent.tag
    marc.each_by_tag(tag) do |df|
      df.each_by_tag(node.tag) do |sf|
        if sf.content != node.content
          ver << false
        else
          ver << true
        end
      end
    end
    res << ver
  end
  return res.flatten.include?(false) ? false : true 
end

process = lambda { |record|
  to_change = false
  marc = record.marc
  content_500 = ""
  old_subfield = nil
  marc.each_by_tag("240") do |n|
    n.each_by_tag("k") do |sf|
      old_subfield = sf
      content_500 = sf.content
      sf.destroy_yourself
    end
  end
  if old_subfield
    to_change = true if same_tag_in_versions?(record, old_subfield)
  end

  if to_change
    new_500 = MarcNode.new(Source, "500", "", "##")
    ip = marc.get_insert_position("500")
    new_500.add(MarcNode.new(Source, "a", "Date: #{content_500}", nil))
    new_500.sort_alphabetically
    marc.root.children.insert(ip, new_500)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} moved 240$k to 500 '#{content_500}'")
    record.save
  end

}

maintenance.execute process
