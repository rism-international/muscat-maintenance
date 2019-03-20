sx = Source.select(:lib_siglum,:wf_stage).where('lib_siglum like ? or lib_siglum like ?', 'I-%', 'V-%').group(:lib_siglum, :wf_stage).size.to_a

ary = []

sx.each do |s|
  siglum = s[0][0]
  wf_stage = s[0][1]
  sum = s[1]
  element = ary.select{|e| e.keys[0] == siglum}
  if element.empty?
    ary << {siglum => {wf_stage => sum}}
  else
    element.first[siglum].merge!({wf_stage => sum})
  end
end

res = []
ary.each do |e|
  siglum = e.flatten[0]
  pub = e.flatten[1]['published']
  unpub = e.flatten[1]['inprogress']
  res << "\"#{siglum}\",\"#{pub ? pub: 0}\",\"#{unpub ? unpub: 0}\""
end
File.write("#{Rails.root}/housekeeping/maintenance/report/2019-03-20_iccu-report.csv", "\"SIGLUM\",\"PUBLISHED\",\"UNPUBLISHED\"\n#{res.sort.join("\n")}")

