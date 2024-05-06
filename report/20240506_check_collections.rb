require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20240506_check_collections.csv"
sources = Source.where(record_type: 1).where('lib_siglum like ? or lib_siglum like ?', "GB%", "US%")
bar = ProgressBar.new(sources.size)
res = []
sources.each do |source|
  bar.increment!
  if source.child_sources.empty?
    res << [source.id.to_s, source.lib_siglum]
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "SIGLUM"]
  res.each do |e|
    csv << e
  end
end
