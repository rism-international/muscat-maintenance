require 'csv'

ofile = "#{Rails.root}/housekeeping/maintenance/report/2020-11-03_people.csv"

people = Person.all
bar = ProgressBar.new(people.size)
res = {}

people.each do |person|
  bar.increment!
  marc = person.marc
  marc.each_by_tag("678") do |tag|
    tag.each_by_tag("b") do |sf|
      puts sf.content
      if sf && sf.content
        if res[person.id]
          res[person.id] << ["b: #{s.content}"]
        else
          res[person.id] = ["b: #{s.content}"]
        end
      else
        next
      end
    end
    tag.each_by_tag("u") do |sf|
      if sf && sf.content
        puts sf.content
        if res[person.id]
          res[person.id] << ["b: #{s.content}"]
        else
          res[person.id] = ["b: #{s.content}"]
        end
      else
        next
      end
    end
  end
end

CSV.open(ofile, "w") do |csv|
  csv << ["COUNTRY", "ID"]
  res.sort_by {|k,v| v}.each do |k,v|
    csv << [v, k]
  end
end

