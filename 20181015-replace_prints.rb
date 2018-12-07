# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Replace 'print'          ##################################"
puts "#######################   Expected collection size: c.174.882    #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT id FROM sources s where marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'").pluck(:id)
#sources = Source.where(id: sx.pluck(:id)) 
PaperTrail.request.disable_model(Source)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |src|
  s = Source.find(src)
  modified = false
  begin
    s.marc.each_by_tag("593") do |t|
      t.each_by_tag("a") do |tn|
        next if !(tn && tn.content)
        if tn.content == "print"
          tn.content = "Print"
          modified = true
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
}

maintenance.execute process
