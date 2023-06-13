require 'csv'
require 'pry'

inputfile = ARGV[0]
outputfile = inputfile.gsub(".csv", ".md")
File.delete(outputfile) if File.exist?(outputfile)

string = "| ID | PRINT/MS | HOLDING | TITLE | SIGLUM | MUSCAT | EXISTENT URI | MANIFEST URI | TEXT | STATUS |  \n| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---|   \n"
File.write(outputfile, string, mode: 'a')
    
CSV.foreach(inputfile) do |row|
   string = "| #{row[0]} | #{row[1]} | #{row[2]} | #{row[3]} | #{row[4]} | <a href=\"#{row[5]}\" target=\"_blank\">Muscat</a> | <a href=\"#{row[6]}\" target=\"_blank\">Existent URL</a> | <a href=\"#{row[7]}\" target=\"_blank\">Manifest</a> | #{row[8]} | #{row[9]} |  \n"
   #string = "| #{row[0]} | #{row[1]} | #{row[2]} | #{row[3]} | #{row[4]} | #{row[5]} | #{row[6]} | #{row[7]} | #{row[8]} | #{row[9]} |  \n"
   File.write(outputfile, string, mode: 'a')
end

