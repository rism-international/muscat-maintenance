ofile = "#{Rails.root}/housekeeping/maintenance/report/2019-11-24_relator.json"
res = []
PACKETS = 10000

def has_relator?(marc)
  marc.each_by_tag("700") do |tag|
    return false if !tag.fetch_first_by_tag("4")
  end
  marc.each_by_tag("710") do |tag|
    return false if !tag.fetch_first_by_tag("4")
  end
  return true
end

sources = Source.all.order(:id)
size = sources.size
bar = ProgressBar.new(sources.size)

(0..(size / PACKETS )).each do |packet|
  GC.start
  sources = Source.order(:id).offset(PACKETS * packet).limit(PACKETS)
  PaperTrail.request.disable_model(Source)
  sources.each do |source|
    source.suppress_reindex
    bar.increment!
    if !source.holdings.empty?
      source.holdings.each do |holding|
        marc = holding.marc
        marc.load_source(false)
        if !has_relator?(marc)
          res << source.id
          binding.pry
        end
      end
    end
    marc = source.marc
    marc.load_source(false)
    if !has_relator?(marc)
      res << source.id
      binding.pry
      next
    end
  end
end
File.write(ofile, res.to_json)

