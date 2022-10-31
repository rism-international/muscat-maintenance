# encoding: UTF-8
puts "##################################################################################################"
puts "#########################      Repair multiple master nodes                   ####################"
puts "################################   Expected size: ca. 45      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

ids = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20221026-repair-multiple_masters.yml")
records = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(records)

masters = %w(100 240 650 651 657 690 691 700 710 730)

process = lambda { |record|
  modified = false
  masters.each do | tag_name |
    record.marc.each_by_tag(tag_name) do |tag|
      mx = tag.fetch_all_by_tag("a")
      mx.each_with_index do | sf, index|
        if index >= 1
          modified = true
          sf.destroy_yourself
        end
        maintenance.logger.info("#{maintenance.host}: ##{record.id} '#{tag_name}' is multiple #{mx.size}")
      end
    end
  end
  if modified
    record.save
  end
}

maintenance.execute process
