require 'pry'
#require "sqlite3"
require 'yaml'
require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/report_245_v2.csv"

pt = YAML.load_file('/home/dev/projects/muscat-maintenance/lib/protypes.yaml')
subs = {}
pt.each do |k,v|
  subs[k] = v.hex.chr('UTF-8')
end
re = Regexp.union(subs.keys)

bar = ProgressBar.new(737613)

res = {}

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "PiKaDo320", "Muscat245", "CREATED_AT", "UPDATED_AT"]
  File.foreach("/home/dev/backup/tit.txt").each do | line |
    if line.start_with?("000")
      bar.increment!
      res = {}
      res[:id] = line[3..-1].strip.to_i
      source_record = Source.where(id: res[:id]).take
      if source_record
        if source_record.versions.empty?
          source = source_record.marc_source.split("\n")
          res[:marc_title] = source.grep(/=245/).first.split("$a").last.strip.split("$c").first.gsub("m̅", "mm").gsub("n̅", "nn")
        end
      else
        res[:marc_title] = nil
      end
    else
      if res[:marc_title] && line.starts_with?("320")
        res[:pikado_title] = line[3..-1].gsub(re, subs).gsub("ÎÆ", "φ").strip
        if res[:pikado_title][-3..-1] != res[:marc_title][-3..-1]
          if res[:marc_title]# && (source.updated_at == source.created_at)
            puts res[:id]
            csv << [res[:id], res[:pikado_title], res[:marc_title]]
          end
        end
      end
    end
  end
end
