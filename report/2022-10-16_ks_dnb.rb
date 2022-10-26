require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2022-10-16_ks_dnb.csv"

people = Institution.all
bar = ProgressBar.new(people.size)
res = {}

people.each do |person|
  bar.increment!
  marc = person.marc
  marc.each_by_tag("024") do |tag|
    tag.each_by_tag("2") do |sf|
      if sf.content == "DNB"
        dnb_id = tag.fetch_first_by_tag("a").content rescue next
        puts dnb_id
        res[dnb_id] = person.id
      end
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["DNB", "ID"]
  res.each do |k,v|
    csv << [k, v]
  end
end

