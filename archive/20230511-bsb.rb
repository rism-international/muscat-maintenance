# encoding: UTF-8
# #
# puts "##################################################################################################"
# puts "########################    ISSUE: Add Digits to BSB             #################################"
# puts "#########################   Expected collection size: 10.000    ##################################"
# puts "##################################################################################################"
# puts ""
#

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
logfile = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.log"
logger = Logger.new(logfile)
host = Socket.gethostname

class Node
  attr_accessor :id, :holding, :url, :text
  def initialize(id, holding, url, text)
    @id = id
    @holding = holding
    @url = url
    @text = text
  end
  def holding?
    return true unless holding.blank?
  end
  def record
    if holding?
      Holding.find(holding)
    else
      Source.find(id)
    end
  end
end

def has_iiif?(marc)
  marc.each_by_tag("856") do |tag|
    sfx = tag.fetch_first_by_tag("x").content rescue nil
    if sfx == "IIIF manifest (digitized source)"
      return true
    end
  end
  return false
end

res = []
CSV.foreach(filename, :headers => false) do |row|
  if row[9] == "true"
    res << Node.new(row[0], row[2], row[7], row[8])
  end
end
bar = ProgressBar.new(res.size)
res.each do |e|
     modified = false
     record = e.record
     marc = record.marc
     next if has_iiif?(marc)
     klass = e.holding? ? Holding : Source
     new_856 = MarcNode.new(klass, "856", "", "##")
     ip = marc.get_insert_position("856")
     new_856.add(MarcNode.new(klass, "u", "#{e.url}", nil))
     new_856.add(MarcNode.new(klass, "x", "IIIF manifest (digitized source)", nil))
     new_856.add(MarcNode.new(klass, "z", "#{e.text}", nil))
     new_856.sort_alphabetically
     marc.root.children.insert(ip, new_856)
     logger.info("#{host}: #{klass} ##{e.id} new IIIf with content '#{e.url}'")
     modified = true
     record.save if modified
     bar.increment!
end

