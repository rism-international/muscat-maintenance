require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20221118_check_593.csv"
sources = Holding.find_each
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  id = "#{source.source_id}:#{source.id}"
  bar.increment!
  nodes = source.marc.by_tags("593")
  if nodes.size > 1
    res << [id, source.lib_siglum, "593 multiple"]
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "SIGLUM", "TAG"]
  res.each do |e|
    csv << [e[0], e[1], e[2]]
  end
end
