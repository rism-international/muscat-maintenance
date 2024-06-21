# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change fields from ICCU                   ##########################"
puts "######################### Expected collection size: ca. 15.000  ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
res = {}

data = CSV.read(filename, headers: :first_row, :col_sep => ",")

data.each do |e|
  res[e[0]] = {'240a' => e[5], '240m' => e[6],'650a' => e[8]}
  if e[7]
    res[e[0]].merge!({
     '690a' => e[7].split(' ')[0], '690n' => e[7].split(' ')[1] 
    })
  end
end

sources = Source.where(id: res.keys)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  klass = "Source"
  record_type = record.record_type
  obj = res[record.id.to_s]
  marc = record.marc
  new_marc = "Marc#{klass}".constantize.new(record.marc_source)
  new_marc.load_source(false)
 
  tag240 = new_marc.root.fetch_first_by_tag("240")
  tag240a = tag240.fetch_first_by_tag("a")
  tag240m = tag240.fetch_all_by_tag("m")
  tag240m.each do |sf|
    sf.destroy_yourself
  end
  tag650 = new_marc.root.fetch_all_by_tag("650")
  tag650.each do |t|
    t.destroy_yourself
  end

  tag240zero = tag240.fetch_first_by_tag("0")
  tag240zero.destroy_yourself

  if obj["240a"]
    tag240a.content = obj["240a"]
  end
  if obj["240m"]
    tag240.add(MarcNode.new("#{klass}".constantize, "m", obj["240m"], nil))
    tag240.sort_alphabetically
  end

 
  if obj["650a"]
    #binding.pry if obj["650a"].include?(";")
    ary = obj["650a"].split(";")
   
    ary.each do |e|
      ip = new_marc.get_insert_position("650")
      new_650 = MarcNode.new("#{klass}".constantize, "650", "", "#7")
      new_650.add(MarcNode.new("#{klass}".constantize, "a", e, nil))
      new_marc.root.children.insert(ip, new_650)
    end
  end
  
  if obj["690a"]
    has_690 = nil
    marc.each_by_tag("690") do |tag|
      a_tag = tag.fetch_first_by_tag("a")
      if a_tag.content == obj["690a"]
        has_690 = a_tag.content
      end
    end

    unless has_690
      ip = new_marc.get_insert_position("690")
      new_690 = MarcNode.new("#{klass}".constantize, "690", "", "#7")
      new_690.add(MarcNode.new("#{klass}".constantize, "a", obj["690a"], nil))
      if obj["690n"]
        new_690.add(MarcNode.new("#{klass}".constantize, "n", obj["690n"], nil))
      end
      new_marc.root.children.insert(ip, new_690)
    end
  end

  import_marc = "Marc#{klass}".constantize.new(new_marc.to_marc)
  import_marc.load_source(false)
  import_marc.import
  record.marc = import_marc
  record.record_type = record_type
  maintenance.logger.info("#{maintenance.host}: #{klass} ##{record.id} changed.")
  record.save!
}

maintenance.execute process

