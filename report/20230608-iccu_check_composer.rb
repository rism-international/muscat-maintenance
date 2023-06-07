require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20230608-ICCU_check_composer.csv"
sources = Source.where(wf_owner: 268).where(record_type: 1)
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  child_res = []
  children = Source.where(source_id: source.id)
  children.each do |c|
    child_res << c.composer
  end
  if !source.composer.blank? and source.composer != "Anonymus" and child_res.uniq.size == 1 and child_res.uniq.first == "Anonymus"
    res << [source.id, "collection", source.composer, source.lib_siglum, source.shelf_mark]
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "TEMPLATE", "100a", "RISM-SIGEL", "Shelfmark"]
  res.each do |e|
    csv << [e[0], e[1], e[2], e[3], e[4]]
  end
end
