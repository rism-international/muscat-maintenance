# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Move remark to genre 'ICCU'  ##################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source REGEXP '=500[^\n]*\[[.$.]]aSubject heading: '")
maintenance = Muscat::Maintenance.new(sources)
further_genres = yaml.map{|k,v| k.split("...")[0] if k.include?("...")}.compact

process = lambda { |record|
  modified = false
  genres = []
  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)
  
  # select remark tags and concert them into the new term
  new_marc.each_by_tag("500") do |tag|
    matched = false
    remark = tag.fetch_first_by_tag("a").content
    if remark.starts_with?("Subject heading: ")
      genre = remark.split("Subject heading: ")[1]
      if yaml.keys.include?(genre)
        genres << yaml[genre]
        matched = true
      else
        further_genres.each do |e|
          if remark.starts_with?(e)
            genres << yaml[e + "..."]
            matched = true
          end
        end
      end
    end
    if matched
      tag.destroy_yourself
      modified = true
    end
  end
  
  #check for existing genres
  existent_genres = new_marc.all_values_for_tags_with_subtag("650", "a")
  new_genres = genres - existent_genres

  new_genres.uniq.each do |genre|
    new_650 = MarcNode.new(Source, "650", "", "##")
    ip = new_marc.get_insert_position("650")
    new_650.add(MarcNode.new(Source, "a", "#{genre}", nil))
    new_650.sort_alphabetically
    new_marc.root.children.insert(ip, new_650)
  end
  

  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    record.save! rescue next
    maintenance.logger.info("#{maintenance.host}: ICCU #{record.id} added genre #{new_genres.join("-")}")
  end
}

maintenance.execute process
