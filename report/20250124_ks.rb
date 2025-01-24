require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20250124_ks.csv"

institutions = Institution.find_each
bar = ProgressBar.new(institutions.size)
res = []

institutions.each do |ins|
  bar.increment!
  marc = ins.marc
  has_tag = marc.has_tag?("368")
  if has_tag
    marc.each_by_tag("368") do |tag|
      tag.each_by_tag("a") do |sf|
        if sf && sf.content
          next
        else
          res << ins.id
        end
      end
    end
  else
    res << ins.id
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID"]
  res.each do |e|
    csv << [e]
  end
end

