require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2022-05-03_ws.csv"
res = ["ID", "Model", "Unicode-Character", "Sample"]

models = ["Source", "Holding", "Person", "Institution", "Publication"]

chars = {"TABULATOR" => "\u0009", "LINETAB" => "\u000B", "NOBREAKSPACE" => "\u00a0",
         "ENQUAD" => "\u2000", "EMQUAD" => "\u2001", "ENSPACE" => "\u2002",
         "OGHAM" => "\u1680", "FOURPEREMSPACE" => "\u2005",
         "SIXPEREMSPACE" => "\u2006", "PUNCTIONSPACE" => "\u2008",
         "THINSPACE" => "\u2009", "HAIRSPACE" => "\u200a", "NARROWNOBREACKSPACE" => "\u202f",
         "ZEROWIDTHSPACE" => "\u200b", "MEDIUMMATHSPACE" => "\u205f", "IDEOGRAPHICSPACE" => "\u3000",
         "MONGOLIAN" => "\u180e", "ZEROWIDTHNONJOINER" => "\u200c", "ZEROWIDTHJOINER" => "\u200d",
         "WORDJOINER" => "\u2060", "ZEROWITHNONBREAKINGSPACE" => "\ufeff",
         "EMSPACE" => "\u2003", "FORMFEED" => "\u000c", 
         "THREEPEREMSPACE" => "\u2004", "FIGURESPACE" => "\u2007",
         "BACKSPACE" => "\u0008", "ESCAPE" => "\u001b", "ALERT" => "\u0007"

}

models.each do |model|
  chars.each do |desc, char |
    records = model.classify.constantize.where('marc_source like ?', "%#{char}%")
    puts "#{model} #{desc}: #{records.size}"

    records.each do |record|
      text = record.marc_source
      i = text.index(char)
      res << [model, record.id, desc, text[i-10..i+10].gsub("\n","").gsub("\r", "").gsub(char, "[#{desc}]")]
      puts res.last.join("---")
    end
  end
end

["User", "StandardTitle", "LiturgicalFeast"].each do |model|
   records = model.classify.constantize.all
   records.each do |record|
     text = record.attributes.map { |key, value| "#{key}=#{value}"  }.join('|')
     chars.each do |desc,char|
       if text.include?(char)
         i = text.index(char)
         res << [model, record.id, desc, text[i-10..i+10].gsub(char, "[#{desc}]")]
         puts res.last.join("---")
       end
     end
   end
end

CSV.open(ofile, "w") do |csv|
  res.each do |e|
    csv << [e[0], e[1], e[2], e[3]]
  end
end

