# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Clear 031 with $o '0'        ##################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sql = "SELECT * FROM sources where marc_source REGEXP '=031[^\n]*\[[.$.]]o0'"
sources = Source.find_by_sql(sql)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|

  modified = false
  incnr = []

  record.marc.by_tags("031").each do |n|
    inc_a = n.fetch_first_by_tag("a").content
    inc_b = n.fetch_first_by_tag("b").content
    inc_c = n.fetch_first_by_tag("c").content
    inr = "#{inc_a}.#{inc_b}.#{inc_c}"
    n.each_by_tag("o") do |sf|
      if sf.content == '0'
        sf.destroy_yourself
        modified = true
        incnr << inr
      end
    end

    n.each_by_tag("q") do |sf|
      if sf.content == 'Taktart ermittelt'
        sf.destroy_yourself if modified
      elsif sf.content =~ /Taktart ermittelt/
        sf.content = sf.content.gsub("Taktart ermittelt")
      end
    end
  end

  if modified
    new_599 = MarcNode.new(Source, "599", "", "##")
    ip = record.marc.get_insert_position("599")
    new_599.add(MarcNode.new(Source, "a", "Taktart überprüfen (#{incnr.join(", ")})", nil))
    record.marc.root.children.insert(ip, new_599)
  end

  if modified
    begin
      record.save
      maintenance.logger.info("#{maintenance.host}: Source #{record.id} Taktart überprüfen: Incipits '#{incnr.join(", ")}'")
    rescue 
      maintenance.logger.info("#{maintenance.host}: Source ERROR #{record.id} Incipits")
    end
  end

}

maintenance.execute process

