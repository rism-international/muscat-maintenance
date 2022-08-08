require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2022-08-08_title.csv"
tx = StandardTitle.all.order(title: :asc)
bar = ProgressBar.new(tx.size)
res = [["ID", "TITLE"]]
sz = 0

tx.each do |title|
  bar.increment!
  if title.get_typus.blank?
    res << [title.id, title.title.gsub("\t", "[TAB]")]
    puts sz+=1
  else
    next
  end
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[0], e[1]]
  end
end

