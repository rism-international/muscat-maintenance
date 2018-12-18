# encoding: UTF-8
puts "##################################################################################################"
puts "#######################  ISSUE : Move 597 at end of 245         ##################################"
puts "#######################   Expected collection size: c.96.330     #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources s where marc_source REGEXP '=597[^\n]*\[[.$.]]a'")
PaperTrail.request.disable_model(Source)
maintenance = Muscat::Maintenance.new(sources)


process = lambda { |source|
  impressum = []
  modified = false
  node_597 = []
  begin
    source.marc.each_by_tag("597") do |t|
      node_597 << t
      t.each_by_tag("a") do |tn|
        impressum << tn.content
      end
      #t.each_by_tag("8") do |tn|
      #  if tn.content == '01'
      #    modified = true
      #  end
      #end
    end

    source.marc.each_by_tag("245") do |t|
      t.each_by_tag("a") do |tn|
        tn.content = "#{tn.content} [#{impressum.join("; ")}]"
        modified = true
      end
    end
    node_597.each do |node| 
      node.destroy_yourself
    end
    
  rescue 
    next
  end
  source.suppress_reindex
  PaperTrail.request(enabled: false) do
    source.save if modified
  end
  maintenance.logger.info("#{maintenance.host}: Source ##{source.id} moved 597 to 245") if modified
  source = nil
}

maintenance.execute process
