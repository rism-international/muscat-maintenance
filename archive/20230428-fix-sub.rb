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
  csv << ['001', '240']
end
logfile = "#{File.dirname($0)}/log/#{File.basename($0, '.rb')}.log"
File.delete(logfile) if File.exist?(logfile)
logger = Logger.new(logfile)
host = Socket.gethostname
data = CSV.read(filename)
data.each do |e|
  res << { '001' => (e[0]).to_i, '240k' => e[1], 'siglum' => e[2], 'status' => e[3]}
end
bar = ProgressBar.new(res.size)



res.each do |e|
  modified = false
  source = Source.find(e['001'])
  record_type = source.record_type
  new_marc = MarcSource.new(source.marc_source)
  new_marc.load_source(false)
  tag240 = new_marc.first_occurance("240")
  old_tag = tag240.to_s
  tag240a = tag240.fetch_first_by_tag("a")
  tag240k = tag240.fetch_first_by_tag("k")
  tag240o = tag240.fetch_first_by_tag("o")
  tag240zero = tag240.fetch_first_by_tag("0")
  tag240k_content = tag240k.content rescue nil
  if tag240k_content
    if tag240k_content == "Arr"
      if tag240o
        tag240o.content = "Arr"
      else
        tag240.add(MarcNode.new(Source, "o", "Arr", nil))
      end
      tag240k.destroy_yourself
      modified = true
      sel = "#moved $karr -> $o"
    elsif tag240k_content =~ /Excerpts\. Arr/ || tag240k_content =~ /Fragments\. Arr/ || tag240k_content == /Sketches\. Arr/
      if tag240o
        tag240o.content = "Arr"
      else
        tag240.add(MarcNode.new(Source, "o", "Arr", nil))
      end
      tag240k.content = tag240k_content.split(".").first
      modified = true
      sel = "#splitted $k"
    else
      sel = "#concat $k to $a"
      new_content = "#{tag240a.content}. #{tag240k_content}"
      tag240a.content = "#{tag240a.content}. #{tag240k_content}"
      title = StandardTitle.find(tag240zero.content)
      if title.referring_sources.size > 1
        tag240zero.destroy_yourself
        tag240k.destroy_yourself
      else
        title.update(title: new_content)
        tag240a.content = new_content
        tag240k.destroy_yourself
      end
    end
  end
  tag240.sort_alphabetically
  new_tag = tag240
  import_marc = MarcSource.new(new_marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  source.marc = import_marc
  source.record_type = record_type
  #binding.pry if sel =~ /CONCAT/
  source.save!
  CSV.open(output, "ab") do |csv|
    csv << [ "https://beta.rism.info/admin/sources/#{e['001']}", "#{sel}", "#{old_tag.strip}\n#{new_tag}"]
  end
       
  logger.info("#{host}: #{source.id} [#{sel}]\n#{old_tag.strip} -->\n#{new_tag}")
end
