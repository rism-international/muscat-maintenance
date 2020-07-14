# encoding: UTF-8
puts "##################################################################################################"
puts "######################  ISSUE : Move 700 bsl to 710 with bnf    ##################################"
puts "########################   Expected collection size: c.40       ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(:wf_owner => 327)

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false

  record_type = record.record_type
  new_marc = MarcSource.new(record.marc_source)
  new_marc.load_source(false)

  new_marc.each_by_tag("700") do |tag|
    four_tag = tag.fetch_first_by_tag("4")
    if four_tag && four_tag.content == 'bsl'
      children = tag.children
      tag.destroy_yourself
      new_710 = MarcNode.new(Source, "710", "", "2#")
      ip = new_marc.get_insert_position("710")
      children.each do |sf|
        new_710.add(sf) if (sf.tag != "0" and sf.tag != "d")
      end
      new_marc.root.children.insert(ip, new_710)
      modified = true
    end
    if modified
      import_marc = MarcSource.new(new_marc.to_marc)
      import_marc.load_source(false)
      import_marc.import
      record.marc = import_marc
      record.record_type = record_type
      record.save!
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} moved 700 with 'bsl' to 710")
    end
      
  end
}

maintenance.execute process

