# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Add 593$a with  'ICCU'        #################################"
puts "#########################   Expected collection size: 50.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
ary = []

CSV.foreach(filename, :headers => true) do |row|
  ary << row[0].to_i
end

sources = Source.where(:id => ary)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  type = nil
  marc = record.marc
  next if marc.has_tag?("593")

  if record.source_id
    parent = Source.find(record.source_id)
    parent_tags = []
    parent.marc.by_tags("593").each do |e|
      parent_tags << e
    end
    if !parent_tags.empty?
      type = parent_tags.first.fetch_first_by_tag("a").content rescue "Manuscript copy"
    else
      type = "Manuscript copy"
    end
  else
    type = "Manuscript copy"
  end
  new_593 = MarcNode.new(Source, "593", "", "##")
  ip = record.marc.get_insert_position("593")
  new_593.add(MarcNode.new(Source, "a", "#{type}", nil))
  new_593.add(MarcNode.new(Source, "8", "01", nil))
  record.marc.root.children.insert(ip, new_593)
  if type
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 593$a '#{type}'")
    record.save
  end

}

maintenance.execute process
