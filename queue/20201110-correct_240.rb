
# encoding: UTF-8
#
puts "##################################################################################################"
puts "##################      ISSUE: Correct 240$o and $k                  #############################"
puts "#########################   Expected collection size: 56.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

filename = "#{File.dirname($0)}/#{File.basename($0, '.rb')}.csv"
hash = {}

CSV.foreach(filename, :headers => true) do |row|
  id = row[0].to_i
  _240k = row[1]
  _240o = row[2]
  hash[id] = {_240k: _240k, _240o: _240o}
end

sources = Source.where(:id => hash.keys).order(id: :asc)
maintenance = Muscat::Maintenance.new(sources)
#PaperTrail.request.disable_model(Source)
 
process = lambda { |record|
  _240k = hash[record.id][:_240k]
  _240o = hash[record.id][:_240o]
  modified = false
  record.suppress_reindex

  record.marc.each_by_tag("240") do |tag|
    if tag.fetch_first_by_tag("k")
      tag.each_by_tag("k") do |sf|
        if _240k.blank?
          sf.destroy_yourself
          modified = true
        else
          sf.content = _240k
          modified = true
        end
      end
    else
      unless _240k.blank?
        tag.add(MarcNode.new(Source, "k", "#{_240k}", nil))
        tag.sort_alphabetically
        modified = true
      end

    end

    if tag.fetch_first_by_tag("o")
      tag.each_by_tag("o") do |sf|
        if _240o.blank?
          sf.destroy_yourself
          modified = true
        else
          sf.content = _240o
          modified = true
        end
      end
    else
      unless _240o.blank?
        tag.add(MarcNode.new(Source, "o", "#{_240o}", nil))
        tag.sort_alphabetically
        modified = true
      end
    end
  end

  if modified
    begin
      record.save
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 240k '#{_240k}'")
      maintenance.logger.info("#{maintenance.host}: #{record.id} added 240o '#{_240o}'")
    rescue 
      maintenance.logger.info("#{maintenance.host}: ERROR #{record.id}")
    end
  end

}

maintenance.execute process



