bar = ProgressBar.new(1367659)

(0..(Source.count / 10000.0).round).each do |e|
  file = File.open("#{Rails.root}/housekeeping/maintenance/report/2019-04-06_key.yml", 'a')
  sx = Source.order(:id).limit(10000).offset(e * 10000)
  ary = []
  sx.each do |s|
    bar.increment!
    s.marc.load_source(false)
    #marc = s.marc.deep_copy
    key_240 = s.marc.root.fetch_first_by_tag("240").fetch_first_by_tag("r").content rescue next
    key_031 = s.marc.root.fetch_first_by_tag("031").fetch_first_by_tag("r").content rescue next
    #s.marc = nil
    if !key_240.blank? && !key_031.blank?
      if key_240 != key_031
        if key_240 =~/[BH]/ && key_031 =~ /[BH]/ 
          ary << "#{s.id}: #{key_240} <=> #{key_031}"
        elsif (key_240 == "b" || key_240 == "b|b") && (key_031 == "b" || key_031 == "b|b") 
          ary << "#{s.id}: #{key_240} <=> #{key_031}"
        end
      end
    end
  end
  unless ary.empty?
    file.write(ary.join("\n") + "\n")
  end
  file.close
end

