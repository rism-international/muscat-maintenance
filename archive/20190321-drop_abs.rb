# encoding: UTF-8
puts "##################################################################################################"
puts "#####################   ISSUE : Drop abs as language from ICCU  ##################################"
puts "#######################   Expected collection size: c.45.000     #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources s where wf_owner = 268 and marc_source REGEXP '=041[^\n]*\[[.$.]]aabs'")
PaperTrail.request.disable_model(Source)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |source|
  modified = false
  begin
    source.marc.each_by_tag("041") do |t|
      t.each_by_tag("a") do |tn|
        if tn.content == 'abs'
          if t.children.size < 2
            t.destroy_yourself
            modified = true
          else
            tn.destroy_yourself
            modified = true
          end
        end
        
      end
    end
    
  rescue 
    next
  end
  source.suppress_reindex
  PaperTrail.request(enabled: false) do
    if modified
      source.save rescue next
    end
  end
  maintenance.logger.info("#{maintenance.host}: Source ##{source.id} removed 'abs' in 041") if modified
  source = nil
}

maintenance.execute process
