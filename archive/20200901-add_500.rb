# encoding: UTF-8
#
puts "##################################################################################################"
puts "######################      ISSUE: Add 500  with ICCU            #################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"

hash = {}

CSV.foreach(filename, :headers => true) do |row|
  hash[row[0].to_i] = row[1]
end

sources = Source.where(:id => hash.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  _500 = hash[record.id]
  modified = false

  if _500
    _500.split(";").each do |e|
      new_500 = MarcNode.new(Source, "500", "", "##")
      ip = record.marc.get_insert_position("500")
      new_500.add(MarcNode.new(Source, "a", e, nil))
      record.marc.root.children.insert(ip, new_500)
      modified = true
    end
  end

  if modified
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} added 500$a '#{_500}'") if _500
    record.save
  end

}

maintenance.execute process



