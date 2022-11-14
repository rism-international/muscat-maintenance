require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20221112_check_subfields.csv"
sources = Source.find_each + Holding.find_each
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  source.marc.each_by_tag("300") do |tag|
    id = source.class.to_s == "Source" ? source.id.to_s : "#{source.source_id}:#{source.id}"
    ["a", "b"].each do |subtag|
      nodes = tag.fetch_all_by_tag(subtag)
      if nodes.size > 1
        res << [id, source.lib_siglum, "300#{nodes.join(', 300')}"]
      end
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "SIGLUM", "TAG"]
  res.each do |e|
    csv << [e[0], e[1], e[2]]
  end
end
