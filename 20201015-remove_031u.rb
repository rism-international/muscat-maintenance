# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################          ISSUE: Remove 031$u            #################################"
puts "#####################   Expected collection size: ca. 700.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where marc_source REGEXP '=031[^\n]*\[[.$.]]u'"
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
    modified = false
    record.suppress_reindex
    bar.increment!
    
    record.marc.by_tags("031").each do |n|
      n.each_by_tag("u") do |sf|
        sf.destroy_yourself
        modified = true
      end
    end
    
    if modified
      begin
        record.save
        logger.info("#{host}: #{record.id} removed 031$u")
      rescue
        logger.info("ERROR #{host}: #{record.id} not removed 031$u")
        next
      end
    end
  end
end

