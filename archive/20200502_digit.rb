# encoding: UTF-8
puts "##################################################################################################"
puts "################################        Add 856$x          #######################################"
puts "############################   Expected size: ca. 20.000      ####################################"
puts "##################################################################################################"
puts ""
require_relative "lib/maintenance"

sources = Holding.find_by_sql("SELECT * FROM holdings where marc_source REGEXP '=856[^\n]*\[[.$.]]z'")

maintenance = Muscat::Maintenance.new(sources)

exact_terms = {
            "Parallelquelle" => "Other",
            "Parallelüberlieferung" => "Other",
            "Referenzquelle" => "Other",
            "Libretto" => "Other",
            "Original catalog entry" => "Other",
            "[bibliographic record]" => "Other",
            "Original catalogue entry" => "Other",
            "Quellenbeschreibung" => "Other",
            "Projektwebseite" => "Other",
            "Hofmeister" => "Other",
            "Edition" => "Other",
            "Zobrazení hudebního incipitu" => "Other",
            "Textbuch" => "Other",
            "Textdruck" => "Other",
            "Digital copy" => "Digitalization",
            "Digital version" => "Digitalization",
            "Digitalizovaný dokument (klikněte pro zobrazení)" => "Digitalization"}

var_terms = {
            "Schriftprobe" => "Other",
            "Wasserzeichen" => "Other",
            "Watermark" => "Other",
            "Homepage" => "Other",
            "Bach" => "Other",
            "Digitized" => "Digitalization",
            "Digitalisat" => "Digitalization"}

process = lambda { |record|
  modified = false
  z_content = ""
  x_content = ""
  record.marc.each_by_tag("856") do |tag|
    next if tag.fetch_first_by_tag("x")
    tag.each_by_tag("z") do |subtag|
      if subtag.content 
        z_content = subtag.content.strip
        if exact_terms[z_content]
          x_content = exact_terms[z_content]
          tag.add(MarcNode.new(Holding, "x", x_content, nil))
          tag.sort_alphabetically
          modified = true
        else
          var_terms.keys.each do |term|
            if z_content =~ Regexp.new(term)
              x_content = var_terms[term]
              tag.add(MarcNode.new(Holding, "x", x_content, nil))
              tag.sort_alphabetically
              modified = true
            end
          end
        end
      end
      maintenance.logger.info("#{maintenance.host}: Holding ##{record.id} '$z#{z_content}' added '$x#{x_content}'") if modified
    end
  end

  if modified
    record.save
  end
}

maintenance.execute process
