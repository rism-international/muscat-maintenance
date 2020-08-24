# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Clear and repair 040 with ICCU       ##########################"
puts "#########################   Expected collection size: ca. 3000  ##################################"
puts "##################################################################################################"
puts ""

PACKETS = 10000
size = Source.where(wf_owner: 268).size
host = Socket.gethostname
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source REGEXP '=240[^\n]*\[[.$.]]n' order by ID LIMIT #{PACKETS} OFFSET #{PACKETS}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    record.suppress_reindex
    bar.increment!
    record.marc.by_tags("240").each do |n|
      n.each_by_tag("n") do |sf|
        n_node.destroy_yourself
      end
    end
    #record.save #rescue next
    #logger.info("#{host}: ICCU #{record.id} removing 240n")
  end
end



