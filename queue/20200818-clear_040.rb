# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Add 040 and 980 to sistina           ##########################"
puts "#########################   Expected collection size: ca. 3000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 315)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  record.suppress_reindex
  marc = record.marc
  has_b = nil
 
  marc.by_tags("040").each_with_index do |n,index|
    n.destroy_yourself unless n.fetch_first_by_tag("b")
    has_b = index if n.fetch_first_by_tag("b") and !has_b
    n.each_by_tag("b") do |sf|
      if index > 0 and has_b != index
        n.destroy_yourself
      end
    end
  end

  marc.by_tags("980").each_with_index do |n, index|
    if index > 0
      n.destroy_yourself
    end
  end

  maintenance.logger.info("#{maintenance.host}: removed multiple 040/980 fields from #{record.id}")
  record.save

}

maintenance.execute process
