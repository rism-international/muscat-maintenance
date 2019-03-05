# encoding: UTF-8
puts "##################################################################################################"
puts "#####################  ISSUE : Repair records with zero record_type   ############################"
puts "#######################   Expected collection size: unknown      #################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"
sources = Source.where(record_type: 0).where('updated_at > ?', Time.parse("2019-02-26"))
bar = ProgressBar.new(sources.size)

sources.each do |source|
  record_type = source.versions.order(:id).last.reify.record_type rescue next
  source.update(record_type: record_type)
  bar.increment!
end
