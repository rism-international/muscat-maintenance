require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2020-05-18_prints.csv"
res = []

def get_date(marc)
  result = nil
  marc.each_by_tag("260") do |tag|
    s = tag.fetch_first_by_tag("c")
    if s && s.content
      if s.content =~ /1[45][0-9][0-9]/ || s.content =~ /1600/
        result = s.content
      else
        next
      end
    end
  end
  return result
end

def get_a1(marc)
  result = nil
  marc.each_by_tag("510") do |tag|
    sa = tag.fetch_first_by_tag("a")
    if sa && sa.content
      if sa.content == "RISM A/I"
        sc = tag.fetch_first_by_tag("c")
        result = sc.content if sc
      else
        next
      end
    end
  end
  return result
end

#sources = Source.where(id: 990036692)
sources_ids = Source.find_by_sql("SELECT id FROM sources s where (record_type=2 or record_type=8) and marc_source REGEXP '=593[^\n]*\[[.$.]]a[Pp]rint'")
sources = Source.where(id: sources_ids)
bar = ProgressBar.new(sources.size)

PaperTrail.request.disable_model(Source)

sources.each do |source|
  source.suppress_reindex
  bar.increment!
  marc = source.marc
  id = source.id
  date = get_date(marc)
  a1 = get_a1(marc)
  binding.pry
  if date
    obj = {id: id, date: date, a1: a1}
    res << obj
    puts obj
  end
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[:date], e[:id], e[:a1]]
  end
end

