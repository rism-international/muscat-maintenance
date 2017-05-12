# encoding: UTF-8
puts "##################################################################################################"
puts "#############  ISSUE #17: Transfer non-integer values from 594$c to $b       #####################"
puts "###########################     Expected collection size: c 15.000         #######################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

ids = []
terms = %w(cemb org orch)

terms.each do |t|
  sx = Sunspot.search(Source) do
    adjust_solr_params do |params|
      params[:q] = "594c_text:#{t}"
      params[:start] = 1
      params[:rows] = 20000
    end
  end
  sx.hits.each do |hit|
    ids << hit.result.id
  end
end

sources = Source.where(:id => ids)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  instrument = ""
  marc = record.marc
  binding.pry
  marc.each_by_tag("594") do |n|
    c = n.fetch_first_by_tag("c") rescue nil
    if c && c.content =~ /org|orch|cemb/
      b = n.fetch_first_by_tag("b")
      if b && b.content
        b.content += (c.content.start_with?("(") && c.content.end_with?(")")) ? "#{c.content}" : " (#{c.content})"
        instrument = c.content
        c.content = "1"
        modified = true
      end
    end
  end
  if modified
    record.save
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} $594c #{instrument} appended to 594b.")
  end
}

maintenance.execute process
