# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Add digitalization marker in 856$x   ################################"
puts "##########################   Expected collection size: 25.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources s where record_type = 8 and marc_source REGEXP '=028[^\n]*\[[.$.]]a'")
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  
  rx = record.marc.by_tags("028")
  next if rx.size > 1
  old_content = rx.first.fetch_first_by_tag("a").content rescue nil
  next unless old_content =~ /;/
  ary = old_content.split(";")
  level = rx.first.fetch_first_by_tag("8").content rescue nil
  if ary.size > 1 && level
    ary.each do |string|
      new_028 = MarcNode.new(Source, "028", "", "20")
      ip = record.marc.get_insert_position("028")
      new_028.add(MarcNode.new(Source, "a", "#{string.strip}", nil))
      new_028.add(MarcNode.new(Source, "8", "#{level}", nil))
      record.marc.root.children.insert(ip, new_028)
    end
  end
  rx.first.destroy_yourself
  modified = true
 
  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} splitted plate_number #{old_content}") if modified
    record.save
  end
}

maintenance.execute process
