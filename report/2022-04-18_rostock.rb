require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2022-04-18_rostock.csv"
res = [{id: "ID", size: "Anzahl Drucke", digit: "Digitalisat vorhanden"}]
#sources = Source.where(id: 990036692)
#sources_ids = Source.find_by_sql("SELECT id FROM sources s where (record_type=2 or record_type=8) and marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'")
#sources = Source.where(id: sources_ids)
holdings = Holding.where(lib_siglum: "D-ROu")

bar = ProgressBar.new(holdings.size)

PaperTrail.request.disable_model(Holding)

holdings.each do |holding|
  holding.suppress_reindex
  digit = "Nein"
  source = Source.where(id: holding.source_id).take
  source.holdings.each do |h|
    if h.marc.has_tag?("856")
      digit = "Ja"
      break
    end
  end
  size = source.holdings.size
  obj = {id: holding.source_id, size: size, digit: digit}
  bar.increment!
  res << obj
  puts obj
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[:id], e[:size], e[:digit]]
  end
end

