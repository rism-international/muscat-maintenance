# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Cleanup 300c values                       #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200512-bnf_300c.yml")

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
  marc.each_by_tag("300") do |n|
    n.each_by_tag("c") do |sf|
      old_content = sf.content
      new_content = replace_all(sf.content,terms)
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
