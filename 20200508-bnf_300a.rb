# encoding: UTF-8
puts "##################################################################################################"
puts "################    ISSUE tasks: Cleanup 300a values                       #######################"
puts "############################   Expected collection size: 10.000 ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

terms = YAML.load_file("#{Rails.root}/housekeeping/maintenance/20200508-bnf_300a.yml")

def replace_all(str, hash)
  new_str = str
  hash.each do |k,v|
    if new_str.include?(k)
      new_str = new_str.gsub(k,v)
    end
  end
  return new_str
end

sources = Source.where(:wf_owner => 327)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("300") do |n|
    n.each_by_tag("a") do |sf|
      new_content = replace_all(sf.content,terms)
      if new_content != sf.content
        modified = true
        maintenance.logger.info("#{maintenance.host}: Source ##{record.id} 300a: '#{sf.content.yellow}' => '#{new_content.green}'")
        sf.content = new_content
      end
    end
  end

  if modified
    record.save
  end

}

maintenance.execute process
