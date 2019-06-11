# encoding: UTF-8
#
puts "##################################################################################################"
puts "##############    ISSUE: Mark LiturgicalFeast from ICCU as deprecated  ###########################"
puts "#########################   Expected collection size: 211.000   ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

feasts = LiturgicalFeast.where(wf_owner: 0).where('created_at between ? and ?', Time.parse("2019-01-01"), Time.parse("2019-01-05"))

feasts.update_all(wf_stage: "deprecated")

feasts = LiturgicalFeast.where.not(wf_stage: "deprecated")

feasts.update_all(wf_stage: "published")


