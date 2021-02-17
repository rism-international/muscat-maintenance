# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Fix countries                 #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

countries = { "AD" => "XA-AD",
  "AT" => "XA-AT",
  "BE" => "XA-BE",
  "CZ" => "XA-CZ",
  "DE" => "XA-DE",
  "ES" => "XA-ES",
  "F" =>  "XA-FR",
  "FR" => "XA-FR",
  "GB" => "XA-GB",
  "HK" => "XB-HK",
  "ID" => "XB-ID",
  "IRLN" => "XA-GB-NIR",
  "IT" => "XA-IT",
  "MC" => "XA-MC",
  "PH" => "XB-PH",
  "PL" => "XA-PL",
  "PT" => "XA-PT",
  "RC" => "XB-TW",
  "SA" => "XB-SA",
  "US" => "XD-US",
}

institutions = Institution.all.order(id: :asc)
maintenance = Muscat::Maintenance.new(institutions)

process = lambda { |record|
  modified = false
  new_c = nil
  old_c = nil
  record.marc.by_tags("043").each do |n|
    n.each_by_tag("c") do |sf|
      if countries.keys.include?(sf.content)
        old_c = sf.content
        new_c = countries[sf.content]
        sf.content = new_c
        modified = true
      end
    end
  end
  
  if modified
    maintenance.logger.info("#{maintenance.host}: #{record.class} #{record.id} changed country '#{old_c}' to '#{new_c}'" )
    record.save #rescue next
  end


}
maintenance.execute process
