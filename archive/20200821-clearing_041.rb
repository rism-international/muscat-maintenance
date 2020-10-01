# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Clear 041 with abs   'ICCU'  ##################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
size = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and wf_stage=0 and marc_source REGEXP '=041[^\n]*\[[.$.]]aabs'").size
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and wf_stage=0 and marc_source REGEXP '=041[^\n]*\[[.$.]]aabs' order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!

    record.marc.by_tags("041").each do |n|
      n.each_by_tag("a") do |sf|
        if sf.content == 'abs'
          n.destroy_yourself
          modified = true
        end
      end
    end
    if modified
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} clearing 041 with abs")
    end
  end
end

