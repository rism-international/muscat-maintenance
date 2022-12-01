# encoding: UTF-8
puts "##################################################################################################"
puts "################################## Group sources to ICCU     ####################################"
puts "##################################################################################################"
puts ""
require_relative "../lib/maintenance"
require 'csv'
ofile = "#{Rails.root}/housekeeping/maintenance/report/20221202_group_iccu.csv"
NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
sources = Source.where(:wf_stage => 1).where('lib_siglum like ?', "I-%").where.not(wf_owner: 268).where("record_type = ? or record_type = ? or record_type = ? or record_type = ?", 1,2,4,6).order(:id)
res = Hash.new(0)
bar = ProgressBar.new(sources.size)

sources.each do |source|
  bar.increment!
  res[source.lib_siglum] += 1
end

CSV.open(ofile, "w") do |csv|
  csv << ["SIGLUM", "AMOUNT"]
  res.sort.each do |e|
    csv << [e[0], e[1]]
  end
end

