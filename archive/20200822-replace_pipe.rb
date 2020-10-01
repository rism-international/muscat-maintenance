# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Replace pipe with  'ICCU'    ##################################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

def replace_pipe(str)
  #if str.count("|") == 1
  #  return str.gsub(" | ", " ").gsub(" |", " ").gsub("| "," ").gsub("|", " ")
  #elsif str =~ /^L'\|/
  #  return str.gsub(/^L'\|/, "L'")
  #elsif str.count("|") > 1
    return str
      .gsub(/(\S)\|(\S)/, '\1 | \2')
      .gsub(/(\S)\|(\s)/, '\1 |\2')
      .gsub(/(\s)\|(\S)/, '\1| \2')
  #end
end

PACKETS = 10000
host = Socket.gethostname
size = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source like '%|%'").size
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(size)

(0..(size / PACKETS )).each do |packet|
  puts "SELECT * FROM sources where wf_owner=268 and marc_source like '%|%' order by id LIMIT #{PACKETS} offset #{PACKETS * packet}"
  GC.start
  sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source like '%|%' order by id LIMIT #{PACKETS} offset #{PACKETS * packet}")
  PaperTrail.request.disable_model(Source)

  sources.each do |record| 
    modified = false
    record.suppress_reindex
    bar.increment!

    record.marc.by_tags("245").each do |n|
      n.each_by_tag("a") do |sf|
        if sf.content =~ /|/
          new_content = replace_pipe(sf.content)
          if sf.content != new_content
            sf.content = new_content
            modified = true
          end
        end
      end
    end
    if modified
      record.save#! rescue next
      logger.info("#{host}: ICCU #{record.id} repair pipe")
    end
  end
end

