# encoding: UTF-8
puts "##################################################################################################"
puts "#######################  ISSUE : Move 597 at end of 245         ##################################"
puts "#######################   Expected collection size: c.96.330     #################################"
puts "##################################################################################################"
puts ""

require 'progress_bar'

sx = Source.find_by_sql("SELECT * FROM sources s where marc_source REGEXP '=597[^\n]*\[[.$.]]a'")
pb = ProgressBar.new(sx.size)
PaperTrail.request.disable_model(Source)
sx.each do |s|
  impressum = ""
  modified = false
  begin
    s.marc.each_by_tag("597") do |t|
      t.each_by_tag("a") do |tn|
        impressum = tn.content
        tn.destroy_yourself
      end
      t.each_by_tag("8") do |tn|
        if tn.content == '01'
          modified = true
          t.destroy_yourself
        end
      end
    end

    s.marc.each_by_tag("245") do |t|
      t.each_by_tag("a") do |tn|
        if modified
          tn.content = "#{tn.content} [#{impressum}]"
        end
      end
    end

  rescue 
    next
  end
  s.suppress_reindex
  PaperTrail.request(enabled: false) do
    s.save if modified
  end
  s = nil
  pb.increment!
end

