#Automatically generate the GND-Beacon file for
#http://dl.rism.info/pnd.txt
#
require 'fileutils'

cfile = "/tmp/r2rml.properties"
File.delete(cfile) if File.exist?(cfile)
FileUtils.cp("#{Rails.root}/housekeeping/maintenance/conf/r2rml.properties", cfile)
f = File.open(cfile, "a")
if ENV["BEACON_USER"].blank? || ENV["BEACON_PW"].blank? || ENV["BEACON_DB"].blank?
  puts "Environment not set! set with: export BEACON_USER=user; export BEACON_PW=pass; export BEACON_DB=db;"
  exit
end

f.write("db.login=#{ENV["BEACON_USER"]}\n")
f.write("db.password=#{ENV["BEACON_PW"]}\n")
f.write("db.url=jdbc:mysql://127.0.0.1:3306/#{ENV["BEACON_DB"]}\n")
f.write("mapping.file=#{Rails.root}/housekeeping/maintenance/conf/person_nested.ttl\n")
f.close

puts "Creating Turtle-File"
%x( "#{Rails.root}"/housekeeping/maintenance/util/r2rml-parser.sh -p /tmp/r2rml.properties )

puts "Updating Database"
%x( "#{Rails.root}"/housekeeping/maintenance/util/s-put http://lab.rism.info:3030/datastore/data default /tmp/pe.ttl)

puts "Creating Beacon-File"
p = RISMRDF::Beacon.new
p.get_data
puts p

puts "Uploading pnd-file"
%x(rsync -avP /tmp/beacon_out.txt stephan@repo.rism.info:BSB/pnd.txt)

puts "Completed!"
