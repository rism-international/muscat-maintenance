# encoding: UTF-8
#
puts "##################################################################################################"
puts "########################    ISSUE: Change Pipe symbol            #################################"
puts "#####################   Expected collection size: ca. 4.000     ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"


folder = Folder.where(name: "Institutions Kalliope", folder_type: "Institution", wf_owner: 30).first_or_create

institutions = Institution.where('id < ?', 40000000).order(id: :asc)

maintenance = Muscat::Maintenance.new(institutions)

process = lambda { |record|
  if record.referring_dependencies.values.sum == 0
    next if record.siglum
    record.marc.by_tags("368").each do |n|
      n.each_by_tag("a") do |sf|
        if sf.content == 'K' || sf.content =~ /K;/ || sf.content == 'B'
          folder.add_item(record)
        end
      end
    end
  end

}
maintenance.execute process
