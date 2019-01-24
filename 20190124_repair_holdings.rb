# encoding: UTF-8
puts "##################################################################################################"
puts "##########    ISSUE #: Repair holdings with orphaned nodes  ######################################"
puts "############                Expected size: ca. 61                    #############################"
puts "##################################################################################################"
puts " "

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
hx = Holding.where(id: yaml.keys)
maintenance = Muscat::Maintenance.new(hx)

process = lambda { |record|
  modified = false
  n = yaml[record.id]
  m = MarcHolding.new(record.marc_source)
  m.load_source(false)
  m.each_by_tag(n.keys.first) do |node|
    binding.pry if record.id == 319840
    if node.to_s.include?(n.values.first)
      node.destroy_yourself
      modified = true
    end
  end
  if modified
    record.marc = m
    record.save
  end
  maintenance.logger.info("#{maintenance.host}: Holding ##{record.id} fixed orphaned node")
}

maintenance.execute process
