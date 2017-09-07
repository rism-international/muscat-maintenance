##!/bin/bash
#
#Automatically generate the GND-Beacon file for
#http://dl.rism.info/pnd.txt
#
#1 call r2rml to generate pe.ttl
#
#
#./r2rml-parser.sh -p r2rml.properties
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

%x( #{prefix + "vendor/rdf/bin/r2rml-parser.sh -p /tmp/r2rml.properties"} )

#2 import pe.ttl to jena
#3 build beacon file from RISM::RDF:Beacon
#4 upload file to webspace


