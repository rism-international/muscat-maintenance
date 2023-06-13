# encoding: UTF-8
puts "##################################################################################################"
puts "################################    ADD IIIF Nodes              ##################################"
puts "##################################################################################################"
puts ""

require 'csv'

LIBS = ["D-Dl", "D-LEm", "D-LEb"]
        
logfile = "#{Rails.root}/housekeeping/maintenance/iiif/changed#{Time.now.strftime("%Y-%m-%d")}.log"
output = "#{Rails.root}/housekeeping/maintenance/iiif/manifest#{Time.now.strftime("%Y-%m-%d")}.csv"

File.delete(output) if File.exist?(output)
CSV.open(output, "ab") do |csv|
    csv << ['ID', 'PRINT/MS', 'HOLDING', 'TITLE', 'SIGLUM', 'MUSCAT', 'EXISTENT URI', 'MANIFEST URI', 'TEXT', 'STATUS']
end

File.delete(logfile) if File.exist?(logfile)
File.delete(output) if File.exist?(output)
logger = Logger.new(logfile)
host = Socket.gethostname
sources = Source.where(lib_siglum: LIBS).where('marc_source like ?', "%Digit%") + Holding.where(lib_siglum: LIBS).where('marc_source like ?', "%Digit%")
bar = ProgressBar.new(sources.size)



def has_iiif?(marc)
  marc.each_by_tag("856") do |tag|
    sfx = tag.fetch_first_by_tag("x").content rescue nil
    if sfx == "IIIF manifest (digitized source)"
      return true
    end
  end
  return false
end

def get_uri(marc)
  res = []
  marc.each_by_tag("856") do |tag|
    uri = tag.fetch_first_by_tag("u").content rescue nil
    sfx = tag.fetch_first_by_tag("x").content rescue nil
    sfz = tag.fetch_first_by_tag("z").content rescue nil
    res << {uri: uri, status: sfx, text: sfz}
  end
  return res

end

def parse_id(string)
  s = string.scan(/id[0-9]+/).first rescue nil
  if s 
    return s.gsub("id", "")
  end
end

def iiif_manifest(id)
  iiif_uri = "https://iiif.slub-dresden.de/iiif/2/#{id}/manifest.json"
  manifest = JSON.load(URI.open(iiif_uri)) rescue nil
  if manifest && manifest["@id"] == iiif_uri
    return iiif_uri, manifest
  else
    binding.pry
    return nil
  end
end

sources.each do |record|
  binding.pry
  #puts record.id
  if record.class.name == "Holding"
    parent = Source.find(record.source_id) rescue nil
  end
  physical = "..."
  id = "..."
  title = "..."
  holding_id = nil
  if parent 
    holding_id = record.id
    physical = "print"
    title = parent.name[0..24]
    id = parent.id
  else
    holding_id = ""
    physical = "ms"
    title = record.name[0..24]
    id = record.id
  end
  nodes = get_uri(record.marc)
  nodes.each do |node|
    manifest_id = parse_id(node[:uri])
    #existent_uri = parse_id(node[:uri])
    #manifest_id = parse_id(existent_uri)
    binding.pry
    if manifest_id
      manifest = iiif_manifest(manifest_id)
      CSV.open(output, "ab") do |csv|
        if manifest
          csv << [id, physical, holding_id, title, record.lib_siglum, "https://muscat.rism.info/admin/sources/#{id}", node[:uri], manifest[0], node[:text], "true"]
        else
          csv << [id, physical, holding_id, title, record.lib_siglum, "https://muscat.rism.info/admin/sources/#{id}", node[:uri], "MISSING", node[:text], "false"]
        end
      end
    else
      binding.pry
    end
  end
  logger.info("#{host}: #{record.id}")
  bar.increment!
end


