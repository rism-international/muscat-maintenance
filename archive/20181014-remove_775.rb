# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Remove unresolved 775    ##################################"
puts "#######################   Expected collection size: c.30         #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
sources = Source.where(id: yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record_type = record.record_type
  modified = false
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)
  new_marc.each_by_tag("775") do |tag|
    tag.each_by_tag("w") do |t|
      if t.content == yaml[record.id].to_s
        tag.destroy_yourself
        modified = true
      end
    end
  end
  import_marc = MarcSource.new(new_marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  record.marc = import_marc
  record.record_type = record_type
  record.save! if modified
  }

maintenance.execute process

