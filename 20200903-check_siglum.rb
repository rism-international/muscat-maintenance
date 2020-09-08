# encoding: UTF-8
#
puts "##################################################################################################"
puts "##################    ISSUE: Check and repair siglum differences      ############################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where wf_owner=268 and source_id is not NULL"
size = Source.find_by_sql(sql).size
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("#{sql} order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!
    
    coll = Source.find(record.source_id)
    csiglum = coll.lib_siglum
    esiglum = record.lib_siglum
    if csiglum != esiglum
      modified = true
    end


    if modified
      #record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} collection-siglum #{csiglum} <> entry-siglum #{esiglum}")
    end
  end
end

