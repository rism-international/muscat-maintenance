# encoding: UTF-8
puts "##################################################################################################"
puts "#############################    ISSUE tasks: Delete 240k                  #######################"
puts "############################   Expected collection size: 200    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

standard_titles = StandardTitle.find_by_sql("select * from standard_titles where title like '%|%' and wf_owner = 0 and created_at between '2019-12-18' and '2019-12-22'")

maintenance = Muscat::Maintenance.new(standard_titles)

process = lambda { |record|
  new_title = record.title.gsub("|", "")
  maintenance.logger.info("#{maintenance.host}: Standard Title ##{record.id} update title from '#{record.title}' to '#{new_title}'")
  record.update(title: new_title)
}

maintenance.execute process
