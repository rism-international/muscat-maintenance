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
  next if record.record_type == 2
  if record.marc.has_tag?("031")
    record.change_template_to(2)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} changed template to manuscript")
  end
}

maintenance.execute process
