# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Replace 'print'          ##################################"
puts "#######################   Expected collection size: c.174.882    #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources_id = Source.find_by_sql("SELECT id FROM sources s where marc_source REGEXP '=593[^\n]*\[[.$.]]aprint'")

PaperTrail.request.disable_model(Source)
maintenance = Muscat::Maintenance.new(Source.where(id: sources_id))

process = lambda { |record|
  modified = false
  begin
    record.marc.each_by_tag("593") do |t|
      t.each_by_tag("a") do |tn|
        next if !(tn && tn.content)
        if tn.content == "print"
          tn.content = "Print"
          modified = true
        end
      end
    end
  rescue => e 
    puts e.inspect
    puts record.id
    next
  end
  record.suppress_reindex
  record.save if modified rescue next
}

maintenance.execute process

