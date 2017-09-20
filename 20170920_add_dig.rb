# encoding: UTF-8
puts "##################################################################################################"
puts "#######################  ISSUE: Add digitalization links of B-Br  ################################"
puts "############################   Expected collection size: 1.348  ##################################"
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
  maintenance.logger.info("#{maintenance.host}: Source ##{s.id} has no holding by B-Br '#{url}'") if sx.total == 0
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
      cnt+=1
    else
      next
    end
  end
end
