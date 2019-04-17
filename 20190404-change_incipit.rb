# encoding: UTF-8
#
puts "##################################################################################################"
puts "#######    ISSUE: Give 031 new number schema with 'ICCU' and add 040 language  ###################"
puts "#########################   Expected collection size: 211.000   ##################################"
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

    unless record.marc.root.fetch_first_by_tag("040")
      new_040 = MarcNode.new(Source, "040", "", "##")
      ip = record.marc.get_insert_position("040")
      new_040.add(MarcNode.new(Source, "b", "ita", nil))
      record.marc.root.children.insert(ip, new_040)
    end

    new_980 = MarcNode.new(Source, "980", "", "##")
    ip = record.marc.get_insert_position("980")
    new_980.add(MarcNode.new(Source, "a", "import", nil))
    record.marc.root.children.insert(ip, new_980)
    
    record.marc.each_by_tag("031") do |tag|
      next if tag.fetch_first_by_tag("c")
      new_a = "1"
      tag_a = tag.fetch_first_by_tag("a")
      new_b = tag_a.content rescue next
      tag_b = tag.fetch_first_by_tag("b")
      new_c = tag_b.content rescue next
      tag_a.content = new_a
      tag_b.content = new_b
      tag.add(MarcNode.new(Source, "c", "#{new_c}", nil))
      tag.sort_alphabetically
    end
    record.save! rescue next
    logger.info("#{host}: ICCU #{record.id} new incipit order")
    new_040 = nil
    new_980 = nil
  end
end
