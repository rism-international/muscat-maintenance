# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Change Hob. in Source #980    #################################"
puts "#########################   Expected collection size: 1.250     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

host = Socket.gethostname
sql = "SELECT * FROM sources where composer like '%Haydn%' and marc_source like '%Hob%: %'"
sources = Source.find_by_sql(sql)
logger = Logger.new("#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log")
bar = ProgressBar.new(sources.size)

sources.each do |record| 
  modified = false
  record.suppress_reindex
  bar.increment!
  old_content = ""
  new_content = ""

  record.marc.by_tags("690").each do |n|
    sfx = n.fetch_all_by_tag("n")
    sfx.each do |sf|
      if sf.content.include?(": ")
        old_content = sf.content
        new_content = sf.content.gsub(": ", ":")
        sf.content = new_content
        modified = true
      end
    end
  end

  if modified
    record.save#! rescue next
    logger.info("#{host}: #{record.id} changed #{old_content} -> #{new_content}")
  end



end



