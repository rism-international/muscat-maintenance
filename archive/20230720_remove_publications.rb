# encoding: UTF-8
# puts "##################################################################################################"
# puts "#############################  ISSUE : Change owner             ##################################"
# puts "#######################   Expected collection size: c.5000     ###################################"
# puts "##################################################################################################"
# puts ""
#

px = Publication.where(wf_stage: "inprogress").where('short_name like ?', "xxxx%").order(:id)
bar = ProgressBar.new(px.size)


# only to check for dependencies instead of detroy_all
px.each do |p|
  bar.increment!
  p.destroy
end




