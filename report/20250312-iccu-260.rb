require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20250312-ICCU_260.csv"
sources = Source.where(wf_owner: 268)
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  source.marc.each_by_tag("260") do |tag|
    #at = tag.fetch_all_by_tag("c")
    unless tag.fetch_first_by_tag("c")
      res << [source.id]
      binding.pry
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID"]
  res.each do |e|
    csv << [e[0]]
  end
end
