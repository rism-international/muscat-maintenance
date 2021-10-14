require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2021-10-14_check_parent.csv"

sql = "select a.id, a.lib_siglum, b.id, b.lib_siglum from sources a inner join sources b on a.source_id = b.id where a.lib_siglum != b.lib_siglum"

res = ActiveRecord::Base.connection.execute(sql)

CSV.open(ofile, "w") do |csv|
  csv << ["SOURCE ID", "LIB_SIGLUM", "COLLECTION ID", "COLLECTION LIB_SIGLUM"]
  res.each do |e|
    csv << [e[0], e[1], e[2], e[3]]
  end
end

