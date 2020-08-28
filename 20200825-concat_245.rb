# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Concat 245 with  'ICCU'       #################################"
puts "#########################   Expected collection size: 211.000   ##################################"
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
    content = []
    
    record.marc.by_tags("245").each do |n|
      n.fetch_all_by_tag("a").each_with_index do |sf, index|
        content << sf.content
        if index > 0
          sf.destroy_yourself
        end
      end
    end

    if content.size > 1
      tag = record.marc.root.fetch_first_by_tag("245")
      sf = tag.fetch_first_by_tag("a")
      sf.content = content.join("{{brk}}")
      modified = true
    end

    if modified
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} concat 245$a")
    end
  end
end

