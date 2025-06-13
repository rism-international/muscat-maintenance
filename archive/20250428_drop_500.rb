# encoding: UTF-8
puts "##################################################################################################"
puts "#########################      Drop 500$a with leading subject heading        ####################"
puts "############################    Expected size: ca. 144.000    ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
bar = ProgressBar.new(114500)

#sx = Source.where("id like ? or id like ? or id like ?", "8506%", "8507%", "8508%").where('marc_source like ?', "%Subject heading:%")

Source.where("id like ? or id like ? or id like ?", "8506%", "8507%", "8508%").where('marc_source like ?', "%Subject heading:%").find_in_batches do |group|
  group.each do |record|
    bar.increment!
    modified = false
    record.marc.each_by_tag("500") do |tag|
      tag.each_by_tag("a") do |sf|
        if sf && sf.content && sf.content.start_with?("Subject heading:")
          tag.destroy_yourself
          modified = true
        end
      end
    end
    if modified
      logger.info("#{host}: #{record.class} ##{record.id}: removed 500$a")
      record.save
    end
  end
end

