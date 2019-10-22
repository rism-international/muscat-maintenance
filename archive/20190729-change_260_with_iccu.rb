# encoding: UTF-8
#
puts "##################################################################################################"
puts "#########################   ISSUE: Change 260 with iccu                 ##########################"
puts "#########################   Expected collection size: ca. 8000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.find_by_sql("SELECT * FROM sources where wf_owner=268 and marc_source REGEXP '=260[^\n]*\[[.$.]]a(Autografo|Copia)'")
maintenance = Muscat::Maintenance.new(sources)

terms = {"autografo incerto" => "Possible autograph manuscript", "autografo" => "Autograph manuscript", "copia ms" => "Manuscript copy", "copia" => "Manuscript copy"}


process = lambda { |record|
  modified = false
  marc = record.marc
  auto_statement = nil
  node = nil
  marc.each_by_tag("260") do |tag|
    tag.each_by_tag("a") do |sf|
      content = sf.content.split(/[,\.]/).first.downcase.strip
      if terms.keys.include?(content)
        auto_statement = content
        if content == sf.content.downcase
          node = sf
        end
      end
    end
  end
  unless marc.has_tag?("593")
    new_593 = MarcNode.new(Source, "593", "", "##")
    ip = marc.get_insert_position("593")
    new_593.add(MarcNode.new(Source, "a", terms[auto_statement], nil))
    new_593.add(MarcNode.new(Source, "8", "01", nil))
    marc.root.children.insert(ip, new_593)
    node.destroy_yourself if node
    modified = true
  end
  if modified
    maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} added 593 '#{auto_statement}'")
    record.save rescue next
  end
}

maintenance.execute process
