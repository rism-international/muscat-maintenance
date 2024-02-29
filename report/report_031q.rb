require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report_031q.csv"
sources = Source.where('marc_source like ?', "%$qt$%")
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  source.marc.each_by_tag("031") do |tag|
    st = tag.fetch_first_by_tag("q").content rescue nil
    sm = tag.fetch_first_by_tag("m").content rescue "--"
    if st == "t"
      res << [source.id, st, sm]
      binding.pry
    else
      next
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "031_m", "031_t"]
  res.each do |e|
    csv << e
  end
end
