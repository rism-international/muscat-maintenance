require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2022-06-28_profession.csv"
ids = Person.find_by_sql("SELECT id FROM people where marc_source REGEXP '=550[^\n]*\[[.$.]]a'")
people = Person.where(id: ids)
bar = ProgressBar.new(people.size)
res = Hash.new(0)


people.each do |person|
  bar.increment!
  person.marc.each_by_tag("550") do |tag|
    node = tag.fetch_first_by_tag("a")
    if node && node.content
      res[node.content] += 1
    end
  end
end

CSV.open(ofile, "w") do |csv|
  res.sort.each do |e|
    csv << [e[0], e[1]]
  end
end

