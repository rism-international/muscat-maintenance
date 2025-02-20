# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Add language                  #################################"
puts "#####################   Expected collection size: ca. 48.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where(wf_owner: 506).find_each
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  ip = record.marc.get_insert_position("040")
  if record.marc.has_tag?("040")
    record.marc.by_tags("040").each do |n|
      if n.fetch_all_by_tag("b").size == 0
        n.add(MarcNode.new(Source, "b", "ger", nil))
        modified = true
      end
    end
  else
    new_040 = MarcNode.new(Source, "040", "", "##")
    new_040.add(MarcNode.new(Source, "b", "ger", nil))
    record.marc.root.children.insert(ip, new_040)
    modified = true
  end
  
  if modified
    maintenance.logger.info("#{maintenance.host}: #{record.class} #{record.id} added $bger" )
    record.save #rescue next
  end


}
maintenance.execute process
