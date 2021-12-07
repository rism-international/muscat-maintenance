# encoding: UTF-8
# #
puts "##################################################################################################"
puts "########################    ISSUE: Add links to Loc              #################################"
puts "#########################   Expected collection size: 3.000     ##################################"
puts "##################################################################################################"
puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[0].to_i
  _856u = row[1]
  _856z = row[2]
  _856x = row[3]
  res[id] = {_856u: _856u, _856z: _856z, _856x: _856x}
end

sources = Source.where(:id => res.keys).order(id: :asc)
maintenance = Muscat::Maintenance.new(sources)
#PaperTrail.request.disable_model(Source)
 
process = lambda { |record|
  hash = res[record.id]
  _856u = hash[:_856u]
  _856z = hash[:_856z]
  _856x = hash[:_856x]
  modified = false
  marc = record.marc
  new_856 = MarcNode.new(Source, "856", "", "4#")
  ip = marc.get_insert_position("856")
  new_856.add(MarcNode.new(Source, "u", "#{_856u}", nil))
  new_856.add(MarcNode.new(Source, "x", "#{_856x}", nil))
  new_856.add(MarcNode.new(Source, "z", "#{_856z}", nil))
  new_856.sort_alphabetically
  marc.root.children.insert(ip, new_856)
  maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{_856u}'")
  modified = true
  record.save if modified
}

maintenance.execute process
