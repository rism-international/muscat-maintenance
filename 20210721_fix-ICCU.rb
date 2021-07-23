# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BLB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"

rows = CSV.read(filename,  :headers => :first_row, :col_sep => ',', :encoding => 'UTF-8').map(&:to_h)
res = {}
rows.each do |row|
  line = {}
  row.each do |k,v|
    next if v.blank?
    next unless k.include?("$")
    tag, subfield = k.split("$")
    if tag == "650" || tag == "383"
      content = v.split(";")
    else
      content = v
    end
    unless line.has_key?(tag)
      line[tag] = [{subfield => content}]
    else
      line[tag] << {subfield => content}
    end
  end
  res[row["RISM ID"]] = line
end
sources = Source.where(:id => res.keys)

#Sunspot.index(sources)
#Sunspot.commit
#exit

maintenance = Muscat::Maintenance.new(sources)

def cleanup(marc, line)
  if line.key?("650")
    marc.each_by_tag("650") do |t|
      t.destroy_yourself
    end
  end
  if line.key?("383")
    marc.each_by_tag("383") do |t|
      t.destroy_yourself
    end
  end
  if line.key?("599")
    marc.each_by_tag("599") do |t|
      t.destroy_yourself
    end
  end
  if line.key?("690")
    marc.each_by_tag("690") do |t|
      t.destroy_yourself
    end
  end
  if line.key?("240")
    sfx = line["240"].map {|s| s.keys.first}
    tag = marc.root.fetch_first_by_tag("240")
    if sfx.include?("a")
      tag.fetch_first_by_tag("0").destroy_yourself
    end
    sfx.each do |e|
      tag.each_by_tag(e) do |sf|
        sf.destroy_yourself
      end
    end
  end
end
  
def update_tag(marc, line)
  check = false
  line.each do |tag, subfields|
    if !marc.has_tag?(tag)
      new_tag = MarcNode.new(Source, tag, "", "##")
      subfields.each do |e|
        e.each do |sf, value|
          if value.is_a? Array 
            value.each_with_index do |v, index|
              if index == 0
                new_tag.add(MarcNode.new(Source, sf, "#{value.first}", nil))
              else
                add_tag = MarcNode.new(Source, tag, "", "##")
                add_tag.add(MarcNode.new(Source, sf, "#{v}", nil))
                add_tag.sort_alphabetically
                ip = marc.get_insert_position(tag)
                marc.root.children.insert(ip, add_tag)
                check = true
              end
            end
          else
            new_tag.add(MarcNode.new(Source, sf, "#{value}", nil))
          end
        end
      end
      new_tag.sort_alphabetically
      ip = marc.get_insert_position(tag)
      marc.root.children.insert(ip, new_tag)
      binding.pry if check
    else
      tag = marc.root.fetch_first_by_tag(tag)
      subfields.each do |e|
        e.each do |sf,value|
          tag.add(MarcNode.new(Source, sf, "#{value}", nil))
        end
      end
      tag.sort_alphabetically
    end
  end
end


process = lambda { |record|
    record.suppress_reindex
    record_type = record.record_type
    marc = MarcSource.new(record.marc_source)
    marc.load_source(false)
 
    line = res[record.id.to_s]
    next if line.empty?
    cleanup(marc, line)
    update_tag(marc, line)

    import_marc = MarcSource.new(marc.to_marc)
    import_marc.load_source(false)
    import_marc.import
    record.marc = import_marc
    record.record_type = record_type if record_type
    begin
      record.save!
      maintenance.logger.info("#{maintenance.host}: #{record.id} changed #{line}")
    rescue 
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id} changed #{line}")
    end




    #fields.each do |k,v|
    #  update_tag(marc, k, v)
    #end

}



=begin
     url = res[record.id]
     if record.marc_source.include?(url.split('://').last)
       next
     end
     marc = record.marc
     new_856 = MarcNode.new(Source, "856", "", "4#")
     ip = marc.get_insert_position("856")
     new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
     new_856.add(MarcNode.new(Source, "x", "Digitalization", nil))
     new_856.add(MarcNode.new(Source, "z", "Digital copy", nil))
     new_856.sort_alphabetically
     marc.root.children.insert(ip, new_856)
     maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new digitizalization with content '#{url}'")
     modified = true
     record.save if modified
=end

maintenance.execute process
