# encoding: UTF-8
puts "##################################################################################################"
puts "################## ISSUE #5: Adding note to 518 postmigration ####################################"
puts "#####################   Expected collection size: 56   ###########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  list_affdat = yaml[record.id.to_s]
  marc = record.marc
  #size_of_518 = marc.by_tags("518").size

  marc.each_by_tag("518") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    a_tag_content = a_tag.content.gsub("Performance date: ", "")
    list_affdat.each do |e|
      db_affdat = DateTime.parse(e.keys.first).strftime("%d.%m.%Y") rescue e.keys.first
      if a_tag_content.start_with?(db_affdat)
        a_tag.content += " [#{e.values.first}]"
        modified = true
        list_affdat.reject! {|a| a == e}
      end
    end
  end

  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} $518a adding afftxt.")
}

maintenance.execute process
