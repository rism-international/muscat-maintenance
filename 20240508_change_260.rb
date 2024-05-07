# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "###################   ISSUE: Change OEN source dates in 260      #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}
CSV.foreach(filename, :headers => true) do |e|
  res[e[0]] = "#{e[1]}"
end

sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
tags = %w(260)

process = lambda { |record|
  modified = false
  tags.each do | tag_name |
    record.marc.each_by_tag(tag_name) do |tag|
      sf = tag.fetch_first_by_tag("c")
      if sf && sf.content == "[s.d.]"
        new_content = res[record.id.to_s]
        sf.content = new_content
        maintenance.logger.info("#{maintenance.host}: ##{record.id} 260$c with '#{new_content}'")
        modified = true
      end
    end
  end
  if modified
    record.save
  end
}


maintenance.execute process


