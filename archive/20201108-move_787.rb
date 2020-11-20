# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Move 787 to 599               #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sql = "SELECT * FROM sources where marc_source REGEXP '=787[^\n]*\[[.$.]]'"
sources = Source.find_by_sql(sql)

maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  content = []
  record.marc.by_tags("787").each do |n|
    content << n.children.map{|t| t.content}.join("; ")
    n.destroy_yourself
  end

  content.each do |e|
    new_599 = MarcNode.new(Source, "599", "", "##")
    ip = record.marc.get_insert_position("599")
    new_599.add(MarcNode.new(Source, "a", "From 787: #{e}", nil))
    record.marc.root.children.insert(ip, new_599)
    maintenance.logger.info("#{maintenance.host}: Source ##{record.id} moved 787 to 599 with content '#{e}'")
    modified = true
  end

  record.save if modified


}
maintenance.execute process
