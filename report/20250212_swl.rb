require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/20250212_swl.csv"
sources = Source.where(lib_siglum: "D-SWl").where(source_id: nil).order(id: :asc)
bar = ProgressBar.new(sources.size)
res = []

sources.each do |s|
  bar.increment!
  composer = s.composer.empty? ? "Collection" : s.composer
  id = s.id
  shelf_mark = s.shelf_mark
  title = s.std_title
  _300a = {}
  _590b = {}
  materials = []

  s.marc.each_by_tag("300") do |tag|
    tag.each_by_tag("8") do |sf|
      if sf && sf.content
        materials << sf.content
      end
    end
  end

  materials.each do |m|
    s.marc.each_by_tag("590") do |tag|
      tag.each_by_tag("8") do |sf|
        if sf.content == m          
          t = tag.fetch_first_by_tag("b")
          if t && t.content
            if _590b[m]
              _590b[m] << t.content
            else
              _590b[m] = [t.content]
            end
          end
        end
      end
    end
  end

  materials.each do |m|
    s.marc.each_by_tag("300") do |tag|
      tag.each_by_tag("8") do |sf|
        if sf.content == m          
          t = tag.fetch_first_by_tag("a")
          if t && t.content
            if _300a[m]
              _300a[m] << t.content
            else
              _300a[m] = [t.content]
            end
          end
        end
      end
    end
  end

  materials.sort.each do |m|
    mat_300 = _300a[m] ? _300a[m].join(", ") : ""
    mat_590 = _590b[m] ? _590b[m].join(", ") : ""
    m == "01" ? res << [shelf_mark, composer, title, mat_300, mat_590, id, m] : res << ["", "", "", mat_300, mat_590, "", m]
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["SIGNATUR", "KOMPONIST", "EINORDNUNGSTITEL", "300$a", "590$b", "RISM-ID", "INDEX"]
  res.each do |e|
    csv << e
  end
end
