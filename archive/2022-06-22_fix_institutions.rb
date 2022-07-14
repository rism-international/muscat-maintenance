KALLIOPE_MAPPING = {
  "K" => "Institution",
  "B" => "Library",
  "V" => "Publisher",
  "C" => "Congress",
  "F" => "Research institute",
}

require_relative "lib/maintenance"
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
PaperTrail.request.disable_model(Institution)
collection = Institution.find_each
bar = ProgressBar.new(collection.size)

collection.each do |record|
  bar.increment!
  record.suppress_reindex
  new_tags = []
  old_tags = []
  modified = false
  # Create 593 from template if there isn't one
  if !record.marc.has_tag?("368")
    next
  else
    record.marc.each_by_tag("368") do |tag|
      tag.each_by_tag("a") do |sf|
        if sf.content =~ /;/
          old_tags << sf.content
          list = sf.content.split(";")
          list.each do |e|
            if KALLIOPE_MAPPING.keys.include?(e.strip)
              new_value = KALLIOPE_MAPPING[e.strip]
              new_368 = MarcNode.new(Institution, "368", "", "##")
              new_368.add(MarcNode.new(Institution, "a", "#{new_value}", nil))
              new_tags << new_368
            end
          end
          tag.destroy_yourself
          modified = true
        else
          if KALLIOPE_MAPPING.keys.include?(sf.content)
            old_tags << sf.content.strip
            new_value = KALLIOPE_MAPPING[sf.content.strip]
            new_368 = MarcNode.new(Institution, "368", "", "##")
            new_368.add(MarcNode.new(Institution, "a", "#{new_value}", nil))
            new_tags << new_368
            tag.destroy_yourself
            modified = true
          end
        end
      end
    end
  end
  new_tags.each do |new_tag|
    ip = record.marc.get_insert_position("368")
    record.marc.root.children.insert(ip, new_tag)
  end
  if modified
    logger.info("'#{host}','Institution','#{record.id}','FROM:#{old_tags.join("; ")}','TO:#{new_tags.map{|t| t.fetch_first_by_tag("a").content}.join("; ")}'")
    record.save
  end
end

