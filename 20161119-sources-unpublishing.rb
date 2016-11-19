# encoding: UTF-8
# ISSUE #1: Setting all records of 456055* to unpublished by request of Bernhard Lutz

sources = Source.where("id like ?", "456055%").where(:wf_stage => 1)

########### VARIABLES ############################################
filename = File.basename(__FILE__, '.rb')
hostname = Socket.gethostname
logger = Logger.new("#{Rails.root}/#{File.dirname(__FILE__)}/log/#{filename}.log")
total = sources.size
logger.info("#{hostname}: Size of Sources with '456055*' --> #{total}")
bar = ProgressBar.new(total)
##################################################################



############# START OF SCRIPT ####################################
sources.each do |source|
  source.update(:wf_stage => 'inprogress')
  logger.info("#{hostname}: #{source.id} updated to unpublished.")
  bar.increment!
end
##################################################################
