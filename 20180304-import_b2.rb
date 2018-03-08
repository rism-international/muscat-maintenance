# encoding: UTF-8
puts "##################################################################################################"
puts "###########################  ISSUE #226: Import B/I              #################################"
puts "############################   Expected size: ca 2.200        ####################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
require 'colorize'

ifile = "housekeeping/maintenance/20180304-import_b2.xml"

Catalogue.paper_trail.disable
Holding.paper_trail.disable
Institution.paper_trail.disable
Person.paper_trail.disable
Source.paper_trail.disable

def create_holdings(source)
  marc = source.marc
  count = 0
  marc.each_by_tag("852") do |t|
    
    # Make a nice new holding record
    holding = Holding.new
    new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
    new_marc.load_source false
    
    # Kill old 852s
    new_marc.each_by_tag("852") {|t2| t2.destroy_yourself}
    
    new_852 = t.deep_copy
    new_marc.root.children.insert(new_marc.get_insert_position("852"), new_852)
    
    st = t.fetch_first_by_tag("u")
    if st && st.content
      if @matcher.match(st.content)
        node = MarcNode.new("holding", "856", "", "##")
        node.add_at(MarcNode.new("holding", "u", st.content, nil), 0)
        node.add_at(MarcNode.new("holding", "z", "[digitized version]", nil), 0)
        node.sort_alphabetically
        new_marc.root.children.insert(new_marc.get_insert_position("856"), node)
        st.destroy_yourself
      else
        $stderr.puts "#{source.id}, 852 $u is not an url"
      end
    end
    
    st = t.fetch_first_by_tag("z")
    if st && st.content
      if @matcher.match(st.content)
        node = MarcNode.new("holding", "856", "", "##")
        node.add_at(MarcNode.new("holding", "u", st.content, nil), 0)
        node.add_at(MarcNode.new("holding", "z", "[bibliographic record]", nil), 0)
        node.sort_alphabetically
        new_marc.root.children.insert(new_marc.get_insert_position("856"), node)
        st.destroy_yourself
      end
    end
		
    new_marc.suppress_scaffold_links
    new_marc.import
    
    holding.marc = new_marc
    holding.source = source
    
    holding.suppress_reindex
    
    begin
      holding.save
    rescue => e
      $stderr.puts"SplitHoldingRecords could not save holding record for #{source.id}"
      $stderr.puts e.message.blue
      next
    end
    
    count += 1
  end

  if count != source.holdings.count && count > 0
    $stderr.puts "Modified #{count} records but record has #{source.holdings.count} holdings. [#{source.id}]"
  else
    ts = marc.root.fetch_all_by_tag("852")
    ts.each {|t2| t2.destroy_yourself}
  end
end


source_file = ifile
model = "Source"
from = 0
if File.exists?(source_file)
  import = MarcImport.new(source_file, model, from.to_i)
  import.import
  $stderr.puts "\nCompleted: "  + Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  puts source_file + " is not a file!"
end

sx = Source.where('created_at > ?', Time.now - 6.hours).where('id like ?', '99312%')

sx.each do |s|
  create_holdings(s)
  s.update(:wf_stage => 0, :wf_audit => 1, :wf_owner => 169, :record_type => 8)
  s.reindex
end

px = Person.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
px.each do |p|
  p.scaffold_marc
  p.reindex
end

ix = Institution.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
ix.each do |i|
  i.scaffold_marc
  i.reindex
end

cx = Catalogue.where('created_at > ?', Time.now - 10.hours).where(:marc_source => nil)
cx.each do |c|
  c.scaffold_marc
  c.reindex
end


