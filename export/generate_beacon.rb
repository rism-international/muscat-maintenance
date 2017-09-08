##!/usr/bin/env/rails r
#
#Automatically generate the GND-Beacon file for
#http://dl.rism.info/pnd.txt
#
#1 call r2rml to generate pe.ttl
require 'fileutils'

current = File.expand_path(File.dirname($0)) + "/"
prefix = File.expand_path(current + "../../../") + "/"

cfile = "/tmp/r2rml.properties"
File.delete(cfile) if File.exist?(cfile)
FileUtils.cp(prefix + "vendor/rdf/conf/r2rml.properties", cfile)
f = File.open(cfile, "a")
f.write("db.login=#{ENV["BEACON_USER"]}\n")
f.write("db.password=#{ENV["BEACON_PW"]}\n")
f.write("db.url=jdbc:mysql://127.0.0.1:3306/#{ENV["BEACON_DB"]}\n")
f.write("mapping.file=#{prefix}/vendor/rdf/conf/mappings/person2.ttl\n")
f.close

puts "Creating Turtle-File"

%x( #{prefix + "vendor/rdf/bin/r2rml-parser.sh -p /tmp/r2rml.properties"} )

puts "Done"

#2 import pe.ttl to jena
fusekiServer = %x(pgrep -f fuseki) 
if fusekiServer == "" 
  puts "Fuseki-Server is down!"
  exit
end
puts "Fuseki-Servers is running under PID: " + fusekiServer

puts "Updating Database"

%x(cd /opt/apache-jena-fuseki/bin && ./s-put http://lab.rism.info:3030/datastore/data default /tmp/pe.ttl)

puts "Done"

# 3 create beacon file
puts "Creating Beacon-File"
rismrdf = File.expand_path(prefix + "/" + "vendor/rdf/lib") + "/rdf.rb"
require_relative rismrdf
p = RISM::RDF::Proxy.new
p.get_data
puts p
puts "Done"

#4 upload file to webspace
puts "Uploading pnd-file"
%x(rsync -avP /tmp/beacon_out.txt stephan@repo.rism.info:BSB/pnd.txt)

puts "Done"
