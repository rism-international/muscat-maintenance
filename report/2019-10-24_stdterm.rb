ofile = "#{Rails.root}/housekeeping/maintenance/report/2019-10-24_stdterm.json"
res = []
StandardTerm.all.order(:term).each do |standard_term|
  res << {standard_term.term =>  standard_term.alternate_terms.gsub(/[\n\r]/, "; ").gsub("; ; ", "; ")} unless standard_term.alternate_terms.blank?
end
File.write(ofile, res.to_json)

