# encoding: UTF-8
puts "##################################################################################################"
puts "###################### ISSUE Fix 730 in case of any punctuation     ##############################"
puts "#####################   Expected collection size: 10.046  ########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)

def update_730(record, tag, content, delete_tag=nil)
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
  rda = false
  marc = record.marc
  new_texts = yaml[ "%09d" % record.id.to_s ]
  post_semicolon = ""
  if record.id > 456082230 and record.id < 457000000
    rda = true
  end
  marc.each_by_tag("730") do |tag|
    if rda
      g_tag = tag.fetch_first_by_tag("g")
      g_tag.content = "RDA"
    end
    existing_tag = tag.deep_copy
    a_tag = tag.fetch_first_by_tag("a")
    next if new_texts.include?(a_tag.content) || !a_tag.content
    k_tag = tag.fetch_first_by_tag("k")
    o_tag = tag.fetch_first_by_tag("o")
    if o_tag && o_tag.content
      existing_text = "#{a_tag.content}. #{o_tag.content}"
      new_texts.each do |t|
        if t == existing_text
          update_730(record, tag, t, o_tag)
          modified = true
          next
        end
      end
    elsif k_tag && k_tag.content
      next if k_tag.content == "Insertions"
      existing_text = "#{a_tag.content}. #{k_tag.content}"
      new_texts.each do |t|
        if t == existing_text
          update_730(record, tag, t, k_tag)
          modified = true
          next
        end
      end
    elsif a_tag
      if a_tag.content == post_semicolon
        modified = true
        tag.destroy_yourself
      end
      existing_text = "#{a_tag.content}".gsub("[", "<").gsub("]", ">")
      new_texts.each do |t|
        if t.include?(";") && t.start_with?(existing_text)
          update_730(record, tag, t)
          modified = true
          maintenance.logger.info("#{maintenance.host}: #{record.id}: #{existing_tag.to_s.strip} --> #{tag}")
          post_semicolon = t.split(";").last.strip
          next
        end
        if t == existing_text
          update_730(record, tag, t)
          modified = true
          next
        end
      end
    else
      puts "WTF..."
    end
    if existing_tag.to_s != tag.to_s
      maintenance.logger.info("#{maintenance.host}: #{record.id}: #{existing_tag.to_s.strip} --> #{tag}")
    end
  end
  record.marc = marc

  record.save if modified
}

maintenance.execute process
