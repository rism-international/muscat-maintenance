# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Cleanup 300c values                       #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

def replace_pipe(str)
  if str.count("|") == 1
    return str.gsub(" | ", " ").gsub(" |", " ").gsub("| "," ").gsub("|", " ")
  elsif str =~ /^L'\|/
    return str.gsub(/^L'\|/, "L'")
  elsif str.count("|") > 1
    return str
      .gsub(/(\S)\|(\S)/, '\1 | \2')
      .gsub(/(\S)\|(\s)/, '\1 |\2')
      .gsub(/(\s)\|(\S)/, '\1| \2')
  end
end

sources = Source.where(:wf_owner => 327)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("245") do |n|
    n.each_by_tag("a") do |sf|
      next unless sf.content =~ /\|/
      old_content = sf.content
      new_content = replace_pipe(sf.content)
      if new_content != old_content
        modified = true
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 300$c: '#{old_content.yellow}' => '#{new_content.green}'")
        sf.content = new_content
      end
    end
  end

  if modified
    record.save
  end
}

maintenance.execute process
