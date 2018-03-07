# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Fix 240 in case of any wrong punctuation   ##########################"
puts "#####################   Expected collection size: ca 3.000  ######################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)

def update_240(record, tag, content, delete_tag=nil)
  std = StandardTitle.where(title: content).take
  unless std
    std = StandardTitle.create(title: content)
  end
  id = std.id
  zero_tag = tag.fetch_first_by_tag("0")
  if zero_tag && zero_tag.content
    StandardTitle.find(zero_tag.content).referring_sources.delete(record) rescue binding.pry
  end
  zero_tag.destroy_yourself rescue nil
  delete_tag.destroy_yourself if delete_tag
  tag.add_at(MarcNode.new("source", "0", id, nil), 0)
  tag.foreign_object = std
  tag.sort_alphabetically
end

process = lambda { |record|
  modified = false
  marc = record.marc
  t = yaml[ "%09d" % record.id.to_s ]
  post_semicolon = ""
  marc.each_by_tag("240") do |tag|
    existing_tag = tag.deep_copy
    a_tag = tag.fetch_first_by_tag("a")
    next if t == a_tag.content || !a_tag.content
    k_tag = tag.fetch_first_by_tag("k")
    o_tag = tag.fetch_first_by_tag("o")
    if o_tag && o_tag.content
      existing_text = "#{a_tag.content}. #{o_tag.content}"
      if t == existing_text
        update_240(record, tag, t, o_tag)
        modified = true
      end
    elsif k_tag && k_tag.content
      next if k_tag.content == "Insertions"
      existing_text = "#{a_tag.content}. #{k_tag.content}"
      if t == existing_text
        update_240(record, tag, t, k_tag)
        modified = true
      end
    elsif a_tag
      if a_tag.content == post_semicolon
        modified = true
        tag.destroy_yourself
      end
      existing_text = "#{a_tag.content}".gsub("[", "<").gsub("]", ">")
      if t.include?(";") && t.start_with?(existing_text)
        update_240(record, tag, t)
        modified = true
        maintenance.logger.info("#{maintenance.host}: #{record.id}: #{existing_tag.to_s.strip} --> #{tag}")
        post_semicolon = t.split(";").last.strip
      end
      if t == existing_text
        update_240(record, tag, t)
        modified = true
      end
    else
      puts "WTF..."
    end
    #puts "#{existing_tag.to_s} --> #{tag}"
    if existing_tag.to_s != tag.to_s
      maintenance.logger.info("#{maintenance.host}: #{record.id}: #{existing_tag.to_s.strip} --> #{t}")
    end
  end
  record.marc = marc

  record.save if modified
}

maintenance.execute process
