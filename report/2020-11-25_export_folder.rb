require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2020-11-25_export_folder.csv"

folder = Folder.where(name: "Institutions Kalliope").take

institutions = Institution.where(id: folder.content).order(id: :asc)
bar = ProgressBar.new(institutions.size)
res = []

institutions.each do |institution|
  ins = {id: institution.id}
  name = institution.name ? institution.name : ''
  address = institution.address ? institution.address : ''
  ins[:name] = name
  ins[:address] = address
  ins[:country] = ''
  ins[:place] = ''
  bar.increment!
  marc = institution.marc
  
  marc.each_by_tag("043") do |tag|
    s = tag.fetch_first_by_tag("c")
    if s && s.content
      ins[:country] = s.content
    else
      ins[:country] = ""
    end
  end
  marc.each_by_tag("551") do |tag|
    s = tag.fetch_first_by_tag("a")
    if s && s.content
      ins[:place] = s.content
    else
      ins[:place] = ""
    end
  end

  res << ins
end

CSV.open(ofile, "w") do |csv|
  csv << ["ID", "NAME", "ADDRESS", "COUNTRY", "PLACE"]
  res.each do |e|
    csv << [e[:id], e[:name], e[:address], e[:country], e[:place]]
  end
end

