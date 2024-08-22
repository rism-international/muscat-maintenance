require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/report_588.csv"
sources = Source.where('marc_source like ?', "%\n=588%")
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  containing = false
  holdings = source.holdings.pluck(:lib_siglum)
  source.marc.each_by_tag("588") do |tag|
    st = tag.fetch_first_by_tag("a").content.gsub(";", "").gsub("[", "").gsub("]", "").gsub(",", "").gsub("/", "") rescue nil
    tag_588 = st.split(" ")
    tag_588.each do |e|
      if !e.include?("-")
        next
      else 
        if holdings.include?(e)
          containing = true
        end
      end
    end
    if containing == false
      res << ["<a href=\"https://muscat.rism.info/admin/sources/#{source.id}\">#{source.id}</a>", st, holdings.join("; ")]
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "588", "Holdings"]
  res.each do |e|
    csv << e
  end
end
