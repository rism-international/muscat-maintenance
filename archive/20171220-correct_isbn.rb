# encoding: UTF-8
puts "##################################################################################################"
puts "###################### Correct ISBN in catalog                      ##############################"
puts "#####################   Expected collection size: ca. 100 ########################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Catalogue.where(:id => yaml.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  isbn = marc.root.fetch_first_by_tag("020")

  unless isbn
    new_isbn = MarcNode.new(Catalogue, "020", "", "1#")
    ip = marc.get_insert_position("020")
    new_isbn.add(MarcNode.new(Catalogue, "a", "#{yaml[record.id]}", nil))
    marc.root.children.insert(ip, new_isbn)
  end

  modified = true
  record.save if modified
  maintenance.logger.info("#{maintenance.host}: Catalogue #{record.id}: added isbn")
}

maintenance.execute process
