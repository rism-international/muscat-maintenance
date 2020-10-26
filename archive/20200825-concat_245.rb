# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Concat 245 with  'ICCU'       #################################"
puts "#########################   Expected collection size: 700.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where wf_owner=268"
size = Source.find_by_sql(sql).size
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("#{sql} order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
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
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} concat 245$a")
    end
  end
end

