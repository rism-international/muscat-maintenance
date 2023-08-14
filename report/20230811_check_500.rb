require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20230811_check_500.csv"
sources = Source.find_each
bar = ProgressBar.new(sources.size)
res = []

sources.each do |source|
  bar.increment!
  source.marc.each_by_tag("500") do |tag|
    tag.each_by_tag("a") do |sf|
      if sf && sf.content
        if sf.content.size > 512
          puts sf.content.size
          puts sf.content
          res << [source.id, sf.content.size, sf.content]
        end
      end
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "SIZE", "500"]
  res.each do |e|
    csv << e
  end
end
