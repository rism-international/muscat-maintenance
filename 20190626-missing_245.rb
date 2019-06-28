# encoding: UTF-8
#
puts "##################################################################################################"
puts "#################    ISSUE: Add 245 '[without title]' in missing field  ##########################"
puts "#########################   Expected collection size: 28.050    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

ids = [989004340, 989004341, 990000026, 990000030, 464001022]

sources = Source.all
#sources = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  if !(record.marc_source =~ /[\r\n]=245\s+[0-9]*[#]*\$a/  )
    unless record.marc.has_tag?("245")
      node_597 = []
      impressum = []
      removed_597 = ""
      if record.marc.has_tag?("775")
        previous_print_id = record.marc.first_occurance("775", "w").content
        previous_print = Source.find(previous_print_id)
        previous_title = previous_print.marc.first_occurance("245", "a").content rescue ""
        if previous_title[-1] == "]"
          previous_title_without_impressum = previous_title.split("[")[0..-2].join("[").strip
        end
        pt = previous_title_without_impressum ? previous_title_without_impressum : previous_title
      end
      marc = record.marc
      new_245 = MarcNode.new(Source, "245", "", "10")
      ip = marc.get_insert_position("245")
      dip_title = !pt.blank? ? pt : "[without title]"
      new_245.add(MarcNode.new(Source, "a", dip_title, nil))
      marc.root.children.insert(ip, new_245)

      marc.each_by_tag("597") do |t|
        node_597 << t
        t.each_by_tag("a") do |tn|
          impressum << tn.content
        end
      end
      unless impressum.empty?
        removed_597 = ", removed 597"
        marc.each_by_tag("245") do |t|
          t.each_by_tag("a") do |tn|
            tn.content = "#{tn.content} [#{impressum.join("; ")}]"
          end
        end
      end
      node_597.each do |node| 
        node.destroy_yourself
      end

      title = marc.first_occurance("245", "a").content
      maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} added '#{title}' at 245#{removed_597}")
      modified = true
      record.save if modified
  end
  end

}

maintenance.execute process
