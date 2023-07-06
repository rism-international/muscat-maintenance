# encoding: UTF-8
# #
puts "##################################################################################################"
puts "########################    ISSUE: Add link type to 856          #################################"
puts "#########################   Expected collection size: 200       ##################################"
puts "##################################################################################################"
puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[1].to_i
  _856u = row[4]
  _856z = row[5]
  _856x = row[6]
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
  marc.each_by_tag("856") do |tag|
    subtag_u = tag.fetch_first_by_tag("u")
    subtag_x = tag.fetch_first_by_tag("x")
    if subtag_u && subtag_u.content == _856u and !subtag_x
      tag.add(MarcNode.new(Source, "x", "#{_856x}", nil))
      tag.sort_alphabetically
      modified = true
    end
  end
  if modified 
    maintenance.logger.info("#{maintenance.host}: ##{record.id} '856$x' added 'Other'") if modified
    record.save
  end
}

maintenance.execute process
