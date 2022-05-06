require 'pry'
require 'csv'

res = {}
id = nil
ary = [["ID", "Incipit-No.", "823", "824"]]
row = []

File.readlines('TIT2.ASC', :encoding => 'ISO-8859-1').each do |line|
  line = line.force_encoding('ISO-8859-1').encode('UTF-8').to_s.gsub("\n", "")
  if line.start_with?("###000")
    tmp_id = line[3..-1].to_i
    if tmp_id != id
      if res[id]
        res[id].each do |field|
          if field.start_with?("824")
            #File.write("./824/#{id}.txt", res[id].join)# rescue binding.pry
          end
        end
      end
      res = {}
      id = nil
    end
    id = tmp_id
    res[id] = []
  else
    if line.start_with?("800")
      row = [id, line]
    end
    if line.start_with?("823")
      row << line
    end 
    if line.start_with?("824")
      row << line
      ary << row
      puts row.to_s
    end
    res[id] << line if res[id]#.force_encoding('ISO-8859-1').encode('UTF-8').to_s rescue next
  end
end

CSV.open("./824/824.csv", "w") do |csv|
  ary.each do |e|
    csv << [e[0], e[1], e[2], e[3]]
  end
end
