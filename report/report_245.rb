require 'pry'
#require "sqlite3"
require 'yaml'
require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/report_245.csv"

pt = YAML.load_file('/home/dev/projects/muscat-maintenance/lib/protypes.yaml')
subs = {}
pt.each do |k,v|
  subs[k] = v.hex.chr('UTF-8')
end
re = Regexp.union(subs.keys)

#db = SQLite3::Database.new "pikado.db"
#rows = db.execute <<-SQL
#  create table records (id varchar(100), pikado320 text, marc245 text);
#SQL

id = nil
marc_title = nil

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "PiKaDo320", "Muscat245"]
  File.foreach("/home/dev/backup/tit.txt").each do | line |
    if line.start_with?("000")
      id = line[3..-1].strip
      source = Source.where(id: id.to_i).take
      if source
        marc_title = source.marc.first_occurance("245", "a").content rescue "---"
      else
        marc_title = "MUSCAT RECORD MISSING"
      end
    else
      if id && line.starts_with?("320")
        pikado_title = line[3..-1].gsub(re, subs).gsub("ÎÆ", "φ").strip
        if pikado_title[-3..-1] != marc_title[-3..-1]
          #db.execute("INSERT INTO records (id, pikado320, marc245) VALUES (?, ?, ?)", [id, pikado_title, marc_title])
          csv << [id, pikado_title, marc_title]
          #res[id] << line[3..-1]
          #puts "#{id} -> PiKaDo: #{pikado_title} <-> MARC: #{marc_title}"
        end
      end
    end
  end
end
