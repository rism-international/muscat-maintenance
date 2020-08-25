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
  sources = Source.where(wf_owner: 268).order(:id).offset(PACKETS * packet).limit(PACKETS)
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    record.suppress_reindex
    bar.increment!

    record.marc.by_tags("040").each_with_index do |n,index|
      n.destroy_yourself unless n.fetch_first_by_tag("b")
      b_node = n.fetch_first_by_tag("b")
      if b_node and b_node.content != 'ita'
        b_node.content = "ita"
      end
      has_b = index if b_node and !has_b
      n.each_by_tag("b") do |sf|
        if index > 0 and has_b != index
          n.destroy_yourself
        end
      end
    end

    if !record.marc.has_tag?("040")
      new_040 = MarcNode.new(Source, "040", "", "##")
      ip = record.marc.get_insert_position("040")
      new_040.add(MarcNode.new(Source, "b", "ita", nil))
      record.marc.root.children.insert(ip, new_040)
    end

    record.save #rescue next
    logger.info("#{host}: ICCU #{record.id} clearing 040")
  end
end



