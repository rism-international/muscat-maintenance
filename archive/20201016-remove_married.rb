# encoding: UTF-8
puts "##################################################################################################"
puts "####################  ISSUE: Add department in 852$b              ################################"
puts "##########################   Expected collection size: 1.800    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

records = Person.where('marc_source like ?', '%married with%')
maintenance = Muscat::Maintenance.new(records)

process = lambda { |record|
  modified = false
  record.marc.each_by_tag("500") do |tag|
    tag.each_by_tag("i") do |sf|
      if sf.content == 'married with'
        sf.content = 'married to'
        modified = true
      end
    end
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: Person Record ##{record.id} changed to 'married to'") if modified
    record.save
  end
}

maintenance.execute process
