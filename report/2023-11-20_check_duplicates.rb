require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2023-11-20_check_duplicates.csv"
sx1 = Source.where(lib_siglum: "D-Bhm").pluck(:shelf_mark) 

hx1 = Holding.where(lib_siglum: "D-Bhm")
hx2 = hx1.map { |h| h.get_shelfmark }

sa = sx1 + hx2


#sx2 = Source.where(lib_siglum: "D-Mbs").pluck(:shelf_mark) + Holding.where(lib_siglum: "D-Mbs").pluck(:shelf_mark)


binding.pry

exit



bar = ProgressBar.new(sx.size)
res = [["ID", "TITLE", "SHELFMARK"]]
sz = 0

sx.each do |s1|
  s2 = Source.where(lib_siglum: "D-Mbs").where(shelf_mark: s1.shelf_mark).take
  bar.increment!
  if s2
    res << [s1.id, s1.title, s1.shelf_mark]
    res << [s2.id, s2.title, s2.shelf_mark]
    puts sz+=1
  else
    next
  end
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[0], e[1], e[2]]
  end
end

