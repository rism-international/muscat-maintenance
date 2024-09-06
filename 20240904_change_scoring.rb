# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change change scoring                     ##########################"
puts "#########################   Expected collection size: ca. 2000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
scoring = {}
CSV.foreach(filename, :headers => true) do |e|
    scoring[e[1]] = "#{e[2]}"
end

sources = Source.find_by_sql("SELECT * FROM sources where std_title REGEXP '(#{scoring.keys.join("|")})$'")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  message = ""
  modified = false
  record_type = record.record_type

  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.each_by_tag("240") do |tag|
    m_tag = tag.fetch_first_by_tag("m")
    if m_tag && scoring.keys.include?(m_tag.content)
      message = "#{m_tag.content.dup} => #{scoring[m_tag.content]}" 
      m_tag.content = scoring[m_tag.content]
      modified = true
    end
  end
  if modified
    import_marc = MarcSource.new(new_marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type
    maintenance.logger.info("#{maintenance.host}: #{record.id} changed 240m #{message}")
    record.save!
  end
}

maintenance.execute process

