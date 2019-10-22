# encoding: UTF-8
#
puts "##################################################################################################"
puts "#################    ISSUE: Move 035 to 510 with A                      ##########################"
puts "#########################   Expected collection size: 90.000    ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

sources = Source.where('id like ? and id not like ?', '99%', '9931%')
#sources = Source.where(id: ids)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false

  if record.marc.has_tag?("035")
    marc = record.marc
    _035 = marc.first_occurance("035")
    series_number = marc.first_occurance("035", "a").content rescue nil
    if marc.has_tag?("510")
      _510a = marc.first_occurance("510", "a").content rescue nil
      _510c = marc.first_occurance("510", "c").content rescue nil
      if _510c == series_number
        if _510a == "RISM A/I"
          marc.first_occurance("510", "a").content = "AI/"
        end
        _035.destroy_yourself
      end
    end
  end
  maintenance.logger.info("#{maintenance.host}: https://beta.rism.info/admin/sources/#{record.id} moved '#{series_number}' to 510")
  modified = true
  #record.save if modified
}

maintenance.execute process
