require 'csv'
include ActionView::Helpers::NumberHelper
ofile = "#{Rails.root}/housekeeping/maintenance/report/2021-10-05-statistics.csv"

ms = Source.where(wf_stage: 1).where("record_type = ? or record_type = ?", 1, 2).size
prints = Source.where(wf_stage: 1).where("record_type = ? or record_type = ?", 3, 8).size
libretti = Source.where(wf_stage: 1).where("record_type = ? or record_type = ? or record_type = ?", 4, 5, 9).size
treats = Source.where(wf_stage: 1).where("record_type = ? or record_type = ? or record_type = ?", 6, 7, 10).size
convoluts = Source.where(wf_stage: 1).where("record_type = ?", 11).size
unknown = Source.where(wf_stage: 1).where("record_type = ?", 0).size
sources = Source.where(wf_stage: 1).count
exemplars = Holding.count
people = Person.count
institutions = Institution.count
publications = Publication.count
works = Work.count

date = DateTime.now.strftime('%Y-%m-%d')
doc = "<html><head></head>\n"

doc += "<style>
body {
 font-family: Arial, Helvetica, sans-serif;

}
table {
   border-collapse: collapse;
   width: 100%;
}

td, th {
  border: 1px solid #ddd;
  padding: 8px;
  width: 50%;
}

th {
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: left;
  background-color: #0570c9;
  color: white;
} 
</style>\n<body><div style='margin: 30px'>"

doc += "<div style='display:inline-block;float:right'><img src='#{Rails.root}/public/images/logo-large-zr.png'></div>\n"
doc += "<div style='display:inline-block;float:left; margin-top: 100px; margin-bottom: 50px; font-size: 2.0em'>RISM OPAC-Statistics for #{date}</div>"

doc += "<div style='margin-top:150px'><table>\n<tr><th>Source template</th><th>Size</th><tr>\n"

doc += "<tr><td>Manuscripts</td><td>#{number_with_delimiter(ms, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Prints</td><td>#{number_with_delimiter(prints, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Libretti</td><td>#{number_with_delimiter(libretti, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Theoretica</td><td>#{number_with_delimiter(treats, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Convoluts</td><td>#{number_with_delimiter(convoluts, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Unkown template</td><td>#{number_with_delimiter(unknown, delimiter: ".")}</td></tr>\n"

doc += "\n</table></div>"


doc += "<div style='margin-top:50px'><table>\n<tr><th>Authority</th><th>Size</th><tr>\n"
doc += "<tr><td>Sources</td><td>#{number_with_delimiter(sources, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Holdings</td><td>#{number_with_delimiter(exemplars, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>People</td><td>#{number_with_delimiter(people, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Institutions</td><td>#{number_with_delimiter(institutions, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Publications</td><td>#{number_with_delimiter(publications, delimiter: ".")}</td></tr>\n"
doc += "<tr><td>Works</td><td>#{number_with_delimiter(works, delimiter: ".")}</td></tr>\n"

#puts "MS size: #{ms}"
#puts "Prints size: #{prints}"
#puts "Libretti size: #{libretti}"
#puts "Theoretica size: #{treats}"
#puts "Convoluts: #{convoluts}"
#puts "Unknown: #{unknown}"
#puts "Exemplar size: #{exemplars}"
#puts "People size: #{people}"
#puts "Institutions size: #{institutions}"
#puts "Publications size: #{publications}"
#puts "Works size: #{works}"
#
doc += "\n</table></div></div></body></html>"

File.write('/tmp/statistics.html', doc)
command = "xvfb-run wkhtmltopdf /tmp/statistics.html /var/www/statistics-#{date}.pdf"
system(command)
