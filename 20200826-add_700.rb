# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Adding 700$4 with  'ICCU'     #################################"
puts "#########################   Expected collection size: 40.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

PACKETS = 10000
host = Socket.gethostname
sql = "SELECT * FROM sources where wf_owner=268 and wf_stage = 0 and marc_source like '%=700%'"
size = Source.find_by_sql(sql).size
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("#{sql} order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    modified = false
    added = false
    record.suppress_reindex
    bar.increment!

    record.marc.by_tags("700").each do |n|
      sfx = n.fetch_all_by_tag("4")
      if sfx.empty?
        n.add(MarcNode.new(Source, "4", "oth", nil))
        n.sort_alphabetically
        added = true
      end
      sfx.each_with_index do |sf, index|
        if index == 0 
          if sf.content.blank?
            sf.content = "oth"
            modified = true
          end
        else
          if sf.content.blank?
            sf.destroy_yourself
            modified = true
          end
        end
      end
    end

    if modified
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} changed 700$4")
    end

    if added
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} added 700$4")
    end



  end
end

