require 'csv'
require 'pry'

inputfile = ARGV[0]
outputfile = inputfile.gsub(".csv", ".html")
File.delete(outputfile) if File.exist?(outputfile)

string = "<html>\n<head>\n<style>table, th, td {  border: 1px solid black;border-collapse: collapse;}</style>\n</head>\n<body><table>\n"
header = "<tr><th>ID</th><th>PRINT/MS</th><th>HOLDING</th><th>TITLE</th><th>SIGLUM</th><th>MUSCAT</th><th>EXISTENT URI</th><th>MANIFEST URI</th><th>TEXT</th><th>STATUS</th><tr>\n"
File.write(outputfile, string, mode: 'a')
File.write(outputfile, header, mode: 'a')
    
CSV.foreach(inputfile) do |row|
   string = "<tr><td>#{row[0]}</td><td>#{row[1]}</td><td>#{row[2]}</td><td>#{row[3]}</td><td>#{row[4]}</td><td><a href=\"#{row[5]}\" target=\"_blank\">Muscat</a></td><td><a href=\"#{row[6]}\" target=\"_blank\">Existent URL</a></td><td><a href=\"#{row[7]}\" target=\"_blank\">Manifest</a></td><td>#{row[8]}</td><td>#{row[9]}</td></tr>\n"
   #string = "| #{row[0]} | #{row[1]} | #{row[2]} | #{row[3]} | #{row[4]} | #{row[5]} | #{row[6]} | #{row[7]} | #{row[8]} | #{row[9]} |  \n"
   File.write(outputfile, string, mode: 'a')
end

File.write(outputfile, "</table></body></html>", mode: 'a')
