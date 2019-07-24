# encoding: UTF-8
#
puts "##################################################################################################"
puts "#################    ISSUE: Move 035 to 510 with B                      ##########################"
puts "#########################   Expected collection size: 28.050    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where('id like ?', '9931%').where(record_type: 8)
maintenance = Muscat::Maintenance.new(sources)
regex_a1 = /^[A-Z]{1,2}\s[1-9]+/
regex_b1 = /^[\[c.\s]*[0-9]{4}\]?\|/

process = lambda { |record|
  modified = false
  a1_number = nil
  b1_number = nil
  marc = record.marc
  has_a1 = false
  has_b1 = false

  #binding.pry if record.id % 100 == 0

  marc.each_by_tag("035") do |node|
    series_number = node.fetch_first_by_tag("a").content.strip rescue nil
    if series_number.match?(regex_a1)
      a1_number = series_number
      node.destroy_yourself
    elsif series_number.match?(regex_b1)
      b1_number = series_number
      node.destroy_yourself
    else
      maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} has CUSTOM LOCAL ID #{series_number}")
    end
  end
  
  marc.each_by_tag("691") do |node|
    existing_series = node.fetch_first_by_tag("a").content rescue ""
    if existing_series == "B/I" or existing_series == "RISM B/I"
      b1_number = node.fetch_first_by_tag("n").content rescue ""
    end
  end

  marc.each_by_tag("510") do |node|
    series = node.fetch_first_by_tag("a")
    series_number = node.fetch_first_by_tag("c")

    if series and (series.content == "B/I" or series.content == "RISM B/I") 
      series.content = "B/I"
      if series_number
        has_b1 = true
      elsif b1_number and !series_number
        node.add(MarcNode.new(Source, "c", b1_number, nil))
        modified = true
        has_b1 = true
      end

    elsif series and (series.content == "A/I" or series.content == "RISM A/I")
      if series_number
        has_a1 = true
      elsif a1_number and !series_number
        node.add(MarcNode.new(Source, "c", a1_number, nil))
        series.content = "A/I"
        modified = true
      end
    end
  end

  if a1_number and !has_a1
    new_510 = MarcNode.new(Source, "510", "", "2#")
    ip = marc.get_insert_position("510")
    new_510.add(MarcNode.new(Source, "a", "A/I", nil))
    new_510.add(MarcNode.new(Source, "c", a1_number, nil))
    marc.root.children.insert(ip, new_510)
    modified = true
  end

  if b1_number and !has_b1
    new_510 = MarcNode.new(Source, "510", "", "2#")
    ip = marc.get_insert_position("510")
    new_510.add(MarcNode.new(Source, "a", "B/I", nil))
    new_510.add(MarcNode.new(Source, "c", b1_number, nil))
    marc.root.children.insert(ip, new_510)
    modified = true
  end

  #binding.pry if record.id % 100 == 0
  #binding.pry if modified
  maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} moved RISM series to 510")
  modified = true
  record.save if modified
}

maintenance.execute process
