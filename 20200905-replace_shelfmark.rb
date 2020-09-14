# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################    ISSUE: Change shelfmark with BSB holding        ##########################"
puts "#########################   Expected collection size: ca. 680   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sx = Source.where(lib_siglum: 'D-Mbs')
hx = Holding.where(lib_siglum: 'D-Mbs')
sources = sx + hx
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  id = record.source_id ? record.source_id : record.id
  modified = false
  marc = record.marc
  old_content = ""
  new_content = ""
  marc.each_by_tag("852") do |tag|
    tag.each_by_tag("c") do |sf|
      if sf.content =~ /Mus.\s{0,1}pr/
        old_content = sf.content
        new_content = sf.content.gsub("Mus. pr.", "Mus.pr.").gsub(/Mus\.pr\.([0-9])/, 'Mus.pr. \1' )
        sf.content = new_content
        modified = true if old_content != new_content
      end
    end
  end
  
  if modified
    maintenance.logger.info("#{maintenance.host}: #{record.class} #{id} changed shelfmark '#{old_content}' to '#{new_content}'" ) if old_content != new_content
    record.save #rescue next
  end
}

maintenance.execute process
