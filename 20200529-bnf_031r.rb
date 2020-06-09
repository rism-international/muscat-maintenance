# encoding: UTF-8
#
puts "##################################################################################################"
puts "##########################    ISSUE: BNF Replace 031$r                         ###################"
puts "#########################   Expected collection size: ca. 20.000   ###############################"
puts "##################################################################################################"
puts ""

PACKETS = 2000


def replace_all(str, hash)
  new_str = str.dup
  hash.sort_by { |key, value| key.size  }.reverse.each { |k, v| new_str[k] &&= v  }
  return new_str.strip
end

size = Source.where(wf_owner: 327).size
host = Socket.gethostname
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)
terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200529-bnf_031r.yml")

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.where(wf_owner: 327).order(:id).offset(PACKETS * packet).limit(PACKETS)
  PaperTrail.request.disable_model(Source)
  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!
    record.marc.each_by_tag("031") do |tag|
      tag.each_by_tag("r") do |sf|
        old_content = sf.content
        if terms.keys.include?(old_content)
          new_content = replace_all(old_content,terms)
          if new_content != old_content
            modified = true
            logger.info("#{host}: Source ##{record.id} 031$r: '#{old_content.yellow}' => '#{new_content.green}'")
            sf.content = new_content
          end
        end
      end
    end

    if modified
      record.save! #rescue next
    end
  end
end
