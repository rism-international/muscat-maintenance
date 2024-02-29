# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change change scoring                     ##########################"
puts "#########################   Expected collection size: ca. 2000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

scoring = {
  "2 V" => "V (2)",
  "2 V, pf" => "V (2), pf",
  "2 fl" => "fl (2)",
  "2 i" => "i (2)",
  "2 vl" => "vl (2)",
  "2 vl, 2 vla, vlc" => "vl (2), vla (2), vlc",
  "2 vl, a-vla, b" => "vl (2), vla, b",
  "2 vl, a-vla, vlc" => "vl (2), vla, vlc",
  "2 vl, b" => "vl (2), b",
  "2 vl, t-vla, vlc" => "vl (2), vla, vlc",
  "2 vl, vla, b" => "vl (2), vla, b",
  "2 vl, vla, vlc" => "vl (2), vla, vlc",
  "2 vl, vlc" => "vl (2), vlc",
  "3 V" => "V (3)",
  "3 V, pf" => "V (3), pf",
  "4 V" => "V (4)",
  "coro" => "Coro",
  "coro maschile" => "Coro maschile",
  "Lute" => "lute",
  "pf4hands" => "pf 4hands",
  "pf 4 hands" => "pf 4hands",  
  "Singst., Klv." => "V, pf",
  "V(1)" => "V"

}

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

