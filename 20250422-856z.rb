# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BLB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = []
CSV.foreach(filename, :headers => true) do |row|
  res << row[0]
end

sources = Source.where(:id => res)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.marc.each_by_tag("856") do | tag |
    changed = false
    x = tag.fetch_first_by_tag("x").content
    z = tag.fetch_first_by_tag("z")
    if z
      if z.content.length < 1 
        z.content = x
        changed = true
      end
    else
      tag.add(MarcNode.new(Source, "z", "Digitalisat", nil))
      tag.sort_alphabetically
      changed = true
    end
    if changed
      maintenance.logger.info("#{maintenance.host}: Source ##{record.id} #{tag.to_s}")
      record.save
    end
  end
}

maintenance.execute process
