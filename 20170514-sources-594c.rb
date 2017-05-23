# encoding: UTF-8
puts "##################################################################################################"
puts "#############  ISSUE #17: Transfer non-integer values from 594$c to $b       #####################"
puts "###########################     Expected collection size: c 18.700         #######################"
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
  n594b = ""
  n594c = ""
  result = ""
  marc = record.marc
  marc.each_by_tag("594") do |n|
    c = n.fetch_first_by_tag("c") rescue nil
    if c && c.content =~ /org|orch|cemb/
      n594c = c.content
      b = n.fetch_first_by_tag("b")
      if b && b.content
        n594b = b.content
        if c.content.end_with?(")") 
          if c.content.start_with?("(")
            b.content += " #{c.content}"
            result = b.content
          else
            if c.content.start_with?(" #{b.content}")
              instrument = c.content.gsub(/.*\s+\(/," (")
              b.content += "#{instrument}"
              result = b.content
            end
          end
        else
          b.content += " (#{c.content})"
          result = b.content
        end
        c.content = "1"
        modified = true
      end
    end
  end
  if modified
    record.save
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 594: '#{n594b.yellow}' + '#{n594c.yellow}' => '#{result.green}'")
  end
}

maintenance.execute process
