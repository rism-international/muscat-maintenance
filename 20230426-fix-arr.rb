# encoding: UTF-8
# # #
# # puts "##################################################################################################"
# # puts "########################    ISSUE: FIX 240o values                ################################"
# # puts "#########################   Expected collection size: 100       ##################################"
# # puts "##################################################################################################"
# # puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
output = "#{File.dirname($0)}/#{File.basename($0, '.rb')}_rest.csv"
File.delete(output) if File.exist?(output)
res = []
CSV.open(output, "ab") do |csv|
  csv << ['001', '240o', 'siglum', 'status']
end
ALLOWED = ["Excerpts","Sketches", "Fragments"]
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
data = CSV.read(filename)
data.each do |e|
  res << { '001' => (e[0]).to_i, '240o' => e[1], 'siglum' => e[2], 'status' => e[3]}
end
bar = ProgressBar.new(res.size)

res.each do |e|
  modified = false
  source = Source.find(e['001'])
  marc = source.marc
  tag240o = marc.first_occurance("240", "o")
  arr = tag240o.content rescue nil
  if arr =~ /[Aa]rr/
    tag240o.content = "Arr"
    modified = true
  else
    new_content = e['240o']
    tag240k = marc.first_occurance("240", "k")
    if ALLOWED.include?(new_content)
      if !tag240k 
        tag240 = marc.first_occurance("240")
        tag240.add(MarcNode.new(Source, "k", new_content, nil))
        tag240o.destroy_yourself
        tag240.sort_alphabetically
        modified = true
      else
        CSV.open(output, "ab") do |csv|
          csv << [ "https://muscat.rism.info/admin/sources/#{e['001']}", e['240o'], e['siglum'], e['status']]
        end
      end
    end
  end
  if modified
    source.save
    logger.info("#{host}: #{source.id} changed 240o" )
    bar.increment!
  end

end


