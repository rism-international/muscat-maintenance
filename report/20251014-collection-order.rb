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
    marc.each_by_tag("774") do |tag|
      tag.each_by_tag("w") do |sf|
        sub = Source.find(sf.content) rescue next
        submarc = sub.marc
        _852 = sub.lib_siglum
        _300tag = submarc.first_occurance("300", "a").content rescue ""
        _590atag = submarc.first_occurance("590", "a").content rescue ""
        _590btag = submarc.first_occurance("590", "b").content rescue ""
        subres = [record.id, sub.id, _852, _300tag, _590atag, _590btag]
        CSV.open("t.csv", "ab") do |csv|
          csv << subres
        end
      end
    end
  end
end

#CSV.open(ofile, "w") do |csv|
#  csv << ["ID", "SIGLUM"]
#  res.each do |e|
#    csv << e
#  end
#end
