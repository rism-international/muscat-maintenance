# encoding: UTF-8
puts "##################################################################################################"
puts "#############################        Fix 1 parts          ########################################"
puts "##########################   Expected size: ca. 150.000       ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

#sources = Source.find_by_sql("SELECT * FROM sources where marc_source like '%1 parts%'")
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
bar = ProgressBar.new(150000)

Source.where("marc_source like '%1 parts%'").find_each do | record |
  bar.increment!
  modified = false
  record.marc.each_by_tag("300") do |tag|
    tag.each_by_tag("a") do |sf|
      sf_old = sf.content rescue next
      if sf_old == "1 parts"
        sf_new = "1 part"
        sf.content = sf_new
        modified = true
        msg = "#{sf_old} ==> #{sf.content}"
        logger.info("#{host}: #{record.class} ##{record.id}: #{msg}")
      elsif sf_old.starts_with?("1 parts ")
        sf_new = sf.content.gsub("1 parts ", "1 part ")
        sf.content = sf_new
        modified = true
        msg = "#{sf_old} ==> #{sf.content}"
        logger.info("#{host}: #{record.class} ##{record.id}: #{msg}")
      elsif sf_old.include?(" 1 parts ")
        sf_new = sf.content.gsub(" 1 parts ", " 1 part ")
        sf.content = sf_new
        modified = true
        msg = "#{sf_old} ==> #{sf.content}"
        logger.info("#{host}: #{record.class} ##{record.id}: #{msg}")
      else 
        next
      end
    end
  end

  if modified

    record.save
  end
end
