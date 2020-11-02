require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2020-11-02_countries.csv"

institutions = Institution.all
bar = ProgressBar.new(institutions.size)
res = {}

institutions.each do |institution|
  bar.increment!
  marc = institution.marc
  marc.each_by_tag("043") do |tag|
    s = tag.fetch_first_by_tag("c")
    if s && s.content
      res[institution.id] = s.content
    else
      next
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["COUNTRY", "ID"]
  res.sort_by {|k,v| v}.each do |k,v|
    csv << [v, k]
  end
end

