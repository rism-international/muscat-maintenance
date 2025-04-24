# encoding: UTF-8
puts "##################################################################################################"
puts "#########################      Repair multiple master nodes                   ####################"
puts "################################   Expected size: ca. 45      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
bar = ProgressBar.new(204375)

masters = %w(260 300 590 592 593)
Source.where("id like ? or id like ? or id like ?", "8506%", "8507%", "8508%").find_in_batches do |group|
  group.each do |record|
    msg = []
    bar.increment!
    modified = false
    masters.each do | tag_name |
      record.marc.each_by_tag(tag_name) do |tag|
      sf = tag.fetch_first_by_tag("8")
      unless sf
        tag.add(MarcNode.new(Source, "8", "01", nil))
        tag.sort_alphabetically
        msg << tag_name
        modified = true
      end
    end
    end
    if modified
      logger.info("#{host}: #{record.class} ##{record.id}: #{msg.join} added material group")
      record.save
    end
  end
end

