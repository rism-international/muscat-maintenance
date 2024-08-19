require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20240819-get-subjects.csv"

sub = StandardTerm.all
bar = ProgressBar.new(sub.size)
res = []

sub.each do |term|
  bar.increment!
  next if term.referring_sources.count == 0
  res << [term.id, term.term, term.alternate_terms]
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "Term", "Alternativ"]
  res.each do |e|
    csv << e
  end
end

