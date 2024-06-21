# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change Material group                     ##########################"
puts "######################### Expected collection size: ca. 15.000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = []

data = CSV.read(filename, headers: :first_row, :col_sep => ",")

data.each do |e|
  res << e[0]
end

sources = Source.where(id: res)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  changed = false
  marc = record.marc
  marc.each_by_tag("593") do |tag|
    a_tag = tag.fetch_first_by_tag("a")
    if a_tag && a_tag.content == "Print"
      a_tag.content = "Additional printed material"
      changed = true
    end
  end
  if changed
    maintenance.logger.info("#{maintenance.host}: ##{record.id} changed.")
    record.save!
  end
}

maintenance.execute process

