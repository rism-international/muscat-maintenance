# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Cleanup 7004 values                       #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200510-bnf_7004.yml")

def replace_all(str, hash)
  new_str = str.dup
  hash.sort_by { |key, value| key.size  }.reverse.each { |k, v| new_str[k] &&= v  }
  return new_str.strip
end

sources = Source.where(:wf_owner => 327)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("700") do |n|
    n.each_by_tag("4") do |sf|
      old_content = sf.content
      new_content = replace_all(sf.content,terms)
      if new_content != old_content
        modified = true
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 700$4: '#{old_content.yellow}' => '#{new_content.green}'")
        sf.content = new_content
      end
    end
  end

  if modified
    record.save
  end
}

maintenance.execute process
