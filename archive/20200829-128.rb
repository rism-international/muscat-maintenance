# encoding: UTF-8
#
puts "##################################################################################################"
puts "######################      ISSUE: Changing 128 with ICCU        #################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"

hash = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[0].to_i
  link = row[1]
  _240 = row[2]
  _500 = row[3]
  hash[id] = {_240: _240, link: link, _500: _500}
end

sources = Source.where(:id => hash.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  _240 = hash[record.id][:_240]
  _500 = hash[record.id][:_500]
  modified = false
  marc = record.marc
  marc.each_by_tag("240") do |n|
    n.each_by_tag("m") do |sf|
      sf.destroy_yourself
    end
    if _240
      _240.split(";").each do |e|
        n.add(MarcNode.new(Source, "m", e, nil))
        n.sort_alphabetically
      end
    end
  end

  if _500
    new_500 = MarcNode.new(Source, "500", "", "##")
    ip = record.marc.get_insert_position("500")
    new_500.add(MarcNode.new(Source, "a", "Scoring: #{_500}", nil))
    record.marc.root.children.insert(ip, new_500)
    modified = true
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 240$m '#{_240}'") if _240
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 500$a '#{_500}'") if _500
    record.save
  end

}

maintenance.execute process



