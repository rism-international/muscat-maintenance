require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20241014_check_order.csv"
sources = Source.where(record_type: 1).where('created_at > ?', Time.parse("2007-01-01"))
bar = ProgressBar.new(sources.size)
res = []
sources.each do |record|
  num = 0
  sorted = true
  bar.increment!
  marc = record.marc
  marc.each_by_tag("774") do |tag|
    tag.each_by_tag("w") do |sf|
      if num == 0
        num = sf.content.to_i
      elsif sf.content.to_i < num
        sorted = false
       end
    end
  end
  unless sorted
    CSV.open("t.csv", "ab") do |csv|
      csv << [record.id]
      binding.pry
    end
  end


end

#CSV.open(ofile, "w") do |csv|
#  csv << ["ID", "SIGLUM"]
#  res.each do |e|
#    csv << e
#  end
#end
