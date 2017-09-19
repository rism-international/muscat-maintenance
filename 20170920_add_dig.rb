# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #28: Add digitalization links #################################"
puts "############################   Expected collection size: 620  ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

yaml = Muscat::Maintenance.yaml
maintenance = Muscat::Maintenance.new(yaml)
cnt=0

yaml.each do |e|
  url = e[e.keys.first]
  ref_a1 = e.keys.first
  sx = Source.solr_search do fulltext ref_a1, :fields => '035a' end
  #puts "this is missing: #{ref_a1}!!" if sx.total == 0
  sx.results.each do |s|
    a1 = s.marc.first_occurance("035", "a").content.split(";").first
    if a1 == ref_a1
      s.holdings.each do |h|
        if h.lib_siglum == 'B-Br'
          marc = h.marc
          new_856 = MarcNode.new(Source, "856", "", "4#")
          ip = marc.get_insert_position("856")
          new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
          new_856.add(MarcNode.new(Source, "z", "[digitized version]", nil))
          marc.root.children.insert(ip, new_856)
          maintenance.logger.info("#{maintenance.host}: Source ##{s.id} B-Br new digitizalization with content '#{url}'")
          modified = true
          h.save if modified
        end
      end
      #puts "#{ref_a1} == #{a1}"
      cnt+=1
    else
      next
      
    end
  end

end
puts cnt

=begin

sources = Source.where(:id => yaml.keys)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  url = yaml[record.id][:url]
  bib = yaml[record.id][:bib]
  object = record.holdings.empty? ? record : record.holdings.where(:lib_siglum => bib).take  
  if !object
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} has no holding from '#{bib}'")
  else
    marc = object.marc
    new_856 = MarcNode.new(Source, "856", "", "4#")
    ip = marc.get_insert_position("856")
    new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
    new_856.add(MarcNode.new(Source, "z", "[digitized version]", nil))
    marc.root.children.insert(ip, new_856)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} #{bib} new digitizalization with content '#{url}'")
    modified = true
    object.save if modified
  end
}

maintenance.execute process
=end
