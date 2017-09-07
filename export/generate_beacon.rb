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

current = File.expand_path(__FILE__) + "/"
#prefix = current + "../../beacon/muscat/"
prefix = current
#prefix = "/home/dev/projects/beacon/"
puts current
#puts File.expand_path(prefix) + "/"

cfile = "/tmp/r2rml.properties"
#File.delete(cfile) if File.exist?(cfile)
#FileUtils.cp(prefix + "muscat/vendor/rdf/conf/r2rml.properties", cfile)
#f = File.open(cfile, "a")
#f.write("db.login=#{ENV["BEACON_USER"]}\n")
#f.write("db.password=#{ENV["BEACON_PW"]}\n")
#f.write("db.url=jdbc:mysql://127.0.0.1:3306/#{ENV["BEACON_DB"]}\n")
#f.write("mapping.file=../conf/mappings/person.ttl")
#f.close



#2 import pe.ttl to jena
#3 build beacon file from RISM::RDF:Beacon
#4 upload file to webspace


