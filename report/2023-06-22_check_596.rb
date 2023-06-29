require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2023-06-22_check_596.csv"
ids = Source.find_by_sql("SELECT id FROM sources where marc_source REGEXP '=596[^\n]*\[[.$.]]aRISM'")
sources = Source.where(id: ids)
bar = ProgressBar.new(sources.size)
res = []


sources.each do |record|
  bar.increment!
  record.marc.each_by_tag("596") do |tag|
    node = tag.fetch_first_by_tag("a")
    if node && node.content
      res << [record.id, node.content]
    end
  end
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[0], e[1]]
  end
end

