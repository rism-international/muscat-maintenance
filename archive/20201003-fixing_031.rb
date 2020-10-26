# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Clear 031 with $o '0'        ##################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
hash = {}

CSV.foreach(filename, :headers => false) do |row|
  id = row[0].to_i
  incnr = row[1]
  content = row[2].strip rescue "-"
  if hash[id]
    hash[id].merge!({incnr => content})
  else
    hash[id] = {incnr => content}
  end
end

sources = Source.where(:id => hash.keys)
maintenance = Muscat::Maintenance.new(sources)
#PaperTrail.request.disable_model(Source)
 
process = lambda { |record|
  modified = false
  record.marc.by_tags("031").each do |n|
    inc_a = n.fetch_first_by_tag("a").content
    inc_b = n.fetch_first_by_tag("b").content
    inc_c = n.fetch_first_by_tag("c").content
    inr = "#{inc_a}.#{inc_b}.#{inc_c}"
    content = hash[record.id][inr]
    if content
      n.each_by_tag("q") do |sf|
        if content == '-'
          sf.destroy_yourself
        else
          sf.content = content
        end
        modified = true
        maintenance.logger.info("#{maintenance.host}: Source #{record.id} #{inr} '#{content}'")
      end
    end
  end

  if modified
    record.save
  end


  
}

maintenance.execute process

 



=begin
sql = "SELECT * FROM sources where marc_source REGEXP '=031[^\n]*\[[.$.]]o0'"
sources = Source.find_by_sql(sql)
maintenance = Muscat::Maintenance.new(sources)
file = "#{Rails.root}/housekeeping/maintenance/20201003-fixing_031.csv"
File.delete(file) if File.exist?(file)

process = lambda { |record|

  modified = false

  record.marc.by_tags("031").each do |n|
    inc_a = n.fetch_first_by_tag("a").content
    inc_b = n.fetch_first_by_tag("b").content
    inc_c = n.fetch_first_by_tag("c").content
    inr = "#{inc_a}.#{inc_b}.#{inc_c}"
    n.each_by_tag("o") do |sf|
      if sf.content == '0'
        modified = true
      end
    end

    n.each_by_tag("q") do |sf|
      if sf.content == 'Taktart ermittelt'
        if modified
          CSV.open("#{Rails.root}/housekeeping/maintenance/20201003-fixing_031.csv", "ab") do |csv| csv << [record.id, inr, "-"] end
        end
      elsif sf.content =~ /Taktart ermittelt/
        if modified
          CSV.open("#{Rails.root}/housekeeping/maintenance/20201003-fixing_031.csv", "ab") do |csv| csv << [record.id, inr, sf.content.gsub!("Taktart ermittelt;", "")] end
        end
      end
    end
  end

  if modified
    begin
      maintenance.logger.info("#{maintenance.host}: Source #{record.id} Taktart überprüfen: Incipits '#{incnr.join(", ")}'")
    rescue 
      maintenance.logger.info("#{maintenance.host}: Source ERROR #{record.id} Incipits")
    end
  end
}

maintenance.execute process

=end
