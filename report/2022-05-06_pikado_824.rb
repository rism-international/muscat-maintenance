require 'pry'
require 'csv'

class Incipit
  attr_accessor :id, :p800, :p823, :p824
  def initialize(id=nil)
    @id = id 
    @p800 = ""
    @p823 = []
    @p824 = []
  end

  def to_s
    "#{id}, #{p800}, #{p823.join(';')}, #{p824.join(';')}"
  end

  def has_semikolon?
    self.p823.size > 1
  end
end

incipit = Incipit.new
f = File.open('./824/824.csv', 'a')
f.write("ID,Incipitnr,PIKaDo 823,PIKaDo 824\n")

File.readlines('TIT2.ASC', :encoding => 'ISO-8859-1').each do |line|
  line = line.force_encoding('ISO-8859-1').encode('UTF-8').to_s.strip
  if line.start_with?("###000")
    id = line[3..-1].to_i
  else
    if line.start_with?("800")
      if incipit.has_semikolon?
        puts incipit
        f.write(incipit.to_s + "\n")
      end
      incipit = Incipit.new(id)
      incipit.p800 = line[3..-1]
      binding.pry
    end
    if line.start_with?("823")
      incipit.p823 << line[3..-1]
    end 
    if line.start_with?("824")
      incipit.p824 << line[3..-1]
    end
  end
end

f.close
#CSV.open("./824/824.csv", "w") do |csv|
#  ary.each do |e|
#    csv << [e[0], e[1], e[2], e[3]]
#  end
#end
