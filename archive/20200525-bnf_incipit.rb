# encoding: UTF-8
#
puts "##################################################################################################"
puts "##########################    ISSUE: BNF Move 031$d to 031$m                   ###################"
puts "#########################   Expected collection size: ca. 20.000   ###############################"
puts "##################################################################################################"
puts ""

PACKETS = 10000

size = Source.where(wf_owner: 327).size
host = Socket.gethostname
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)
terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200525-bnf_incipit.yml")

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.where(wf_owner: 327).order(:id).offset(PACKETS * packet).limit(PACKETS)
  PaperTrail.request.disable_model(Source)
  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!
    record.marc.each_by_tag("031") do |tag|
      if tag.fetch_first_by_tag("d")
        tag_031d = tag.fetch_first_by_tag("d")
        tag_031d_content = tag_031d.content
        if terms.include?(tag_031d_content)
          tag.add(MarcNode.new(Source, "m", "#{tag_031d_content}", nil))
          tag.sort_alphabetically
          tag_031d.destroy_yourself
          modified = true
        end
      else 
        next
      end
    end
    if modified
      record.save! #rescue next
      logger.info("#{host}: BNF #{record.id} moved 031$d to 031$m")
    end
  end
end
