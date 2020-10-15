require "yaml"
require 'csv'

class Converter
  
  attr_accessor :languages

  def initialize(file)
    @file = file
    @languages = ["en", "de", "it", "fr", "es", "pl"] 
  end

  def to_string
    puts @file
  end

  def to_csv
    res = []
    yaml = YAML.load_file(@file)
    yaml.keys.each do |e|
      l = []
      l << e
      languages.each do |language|
        l << yaml[e]["label"][language] 
      end
      res << l
    end
    CSV.open("converter.csv", "wb") do |csv|
      res.each do |term|
        csv << term
      end
    end
  end

  #TODO write this method
  def to_yaml
    # write yaml
  end

end

file = ARGV[0]
converter = Converter.new(file)
converter.to_csv



