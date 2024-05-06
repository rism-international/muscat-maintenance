# encoding: UTF-8
puts "##################################################################################################"
puts "#########################      Repair multiple master nodes                   ####################"
puts "################################   Expected size: ca. 45      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

ids = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20240404_material.yml")
records = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(records)
masters = %w(260 300 590 593)

process = lambda { |record|
  modified = false
  masters.each do | tag_name |
    record.marc.each_by_tag(tag_name) do |tag|
      sf = tag.fetch_first_by_tag("8")
      unless sf
        tag.add(MarcNode.new(Source, "8", "01", nil))
        tag.sort_alphabetically
        maintenance.logger.info("#{maintenance.host}: ##{record.id} '#{tag_name}' material group 01 added")
        modified = true
      end
    end
  end
  if modified
    record.save
  end
}

maintenance.execute process
