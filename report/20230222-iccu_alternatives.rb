require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20230222-ICCU_alternatives.csv"
sources = Source.where(wf_owner: 268)
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  source.marc.each_by_tag("730") do |tag|
    at = tag.fetch_all_by_tag("a")
    rule = tag.fetch_all_by_tag("g")
    ary = (at.map{|e| e.content}).zip(rule.map{|e| e.content})
    ary.each do |x|
      puts x
      a,r = x
      if r == "ICCU"
        res << [source.id, a, r]
      end
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "730$a"]
  res.each do |e|
    csv << [e[0], e[1]]
  end
end
