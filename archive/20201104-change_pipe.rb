# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Change Pipe symbol            #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where marc_source REGEXP '=510[^\n]*\[[.$.]]c'"
size = Source.find_by_sql(sql).size
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  puts packet
  sources = Source.find_by_sql("#{sql} order by id LIMIT #{PACKETS}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record|
    previous = ""
    afterwards = ""
    modified = false
    record.suppress_reindex
    bar.increment!
    
    record.marc.by_tags("510").each do |n|
      n.each_by_tag("c") do |sf|
        if sf && sf.content =~ /\|/
          previous = sf.content
          sf.content = sf.content.gsub("\|", "¦")
          afterwards = sf.content
          modified = true
        end
      end
    end
    
    if modified
      begin
        record.save
        logger.info("#{host}: #{record.id} changed 510$c from '#{previous}' to '#{afterwards}'")
      rescue
        logger.info("ERROR #{host}: #{record.id} not changed 510$c")
        next
      end
    end
  end
end

