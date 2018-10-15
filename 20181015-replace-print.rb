# encoding: UTF-8
puts "##################################################################################################"
puts "#############################  ISSUE : Replace 'print'          ##################################"
puts "#######################   Expected collection size: c.174.882    #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources s where marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'")

maintenance = Muscat::Maintenance.new(sources)
process = lambda { |record|
  modified = false
  PaperTrail.request.disable_model(Source)
  record.marc.each_by_tag("593") do |t|
    t.each_by_tag("a") do |tn|
      next if !(tn && tn.content)
      if tn.content == "print"
        tn.content = "Print"
        modified = true
      end
    end
  end
  record.save if modified rescue next
}

maintenance.execute process

