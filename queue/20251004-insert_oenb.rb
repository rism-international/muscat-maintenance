# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to OENB            #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#
require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}
res0 = {"0" => []}

CSV.foreach(filename, :headers => false) do |row|
  id = row[0]
  url = row[2]
  shelfmark = row[1]
  todo = row[3]
  if id == "0"
    res0["0"] << [url, shelfmark, todo]
  else
    if res.keys.include?(id)
      res[id] << [url, shelfmark, todo]
    else
      res[id] = [[url, shelfmark, todo]]
    end
  end
end


sources = Source.where(:id => res.keys)
maintenance = Muscat::Maintenance.new(sources)
   
process = lambda { |record|
     modified = false
     marc = record.marc
     rows = res[record.id.to_s]
     rows.each do |row|
       todo = row[2]
       url = row[0]

       if todo == "new_tag"
         new_856 = MarcNode.new(Source, "856", "", "4#")
         ip = marc.get_insert_position("856")
         new_856.add(MarcNode.new(Source, "u", "#{url}", nil))
         new_856.add(MarcNode.new(Source, "x", "Digitized", nil))
         new_856.add(MarcNode.new(Source, "z", "Digital copy", nil))
         new_856.sort_alphabetically
         maintenance.logger.info("#{maintenance.host}: Source ##{record.id} new url '#{url}'")
         marc.root.children.insert(ip, new_856)

       elsif todo == "https"
         marc.each_by_tag("856") do |tag|
           tag.each_by_tag("u") do |u|
             if u.content.include?(url.gsub("https", ""))
               u.content = url
               maintenance.logger.info("#{maintenance.host}: Source ##{record.id} url https replacing http '#{url}'")
             end
           end
         end
       else
       end
     end

     modified = true
     record.save if modified
}

maintenance.execute process



=begin
res.each do |e|    
  shelfmark = "Mus%Hs%#{e[0]}"
  #puts shelfmark
  url = e[1].gsub("https", "")
  record = Source.where("marc_source like ?", "%#{url}%").take
  if record
    record.marc.each_by_tag("856") do |tag|
      tag.each_by_tag("u") do |u|
        if u.content.include?(url)
          CSV.open("t.csv", "ab") do |csv|
            csv << [record.id, shelfmark, "https#{url}","https"]
          end
          #binding.pry
          #u.content = "https#{url}"
          #binding.pry
        end
      end
    end

    #puts "++++#{e[0]}"

    next
  end
  binding.pry
  record = Source.where(lib_siglum: "A-Wn").where("shelf_mark like ?", shelfmark).take
  if !record
    CSV.open("t.csv", "ab") do |csv|
      csv << [0, shelfmark, "https#{url}", "probably_new_tag"]
    puts "----#{shelfmark}"
    #next
  end
  #record = Source.where(shelf_mark: shelfmark).take
  begin
    CSV.open("t.csv", "ab") do |csv|
      csv << [record.id, shelfmark, "https#{url}", "new_tag"]
      #bar.increment!
    end
  rescue
    binding.pry
    #bar.increment!
  end


end
=end

