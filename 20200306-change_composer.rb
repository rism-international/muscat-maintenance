# encoding: UTF-8
#
puts "##################################################################################################"
puts "####################   ISSUE: Change composer in folder                 ##########################"
puts "#########################   Expected collection size: 212       ##################################"
puts "##################################################################################################"
puts ""

require_relative "lib/maintenance"

folder = Folder.find(383)
idx = folder.folder_items.pluck(:item_id)
composer = Person.find(30007675)
sources = Source.where(id: idx)
maintenance = Muscat::Maintenance.new(sources)

process = lambda { |record|
  modified = false
  marc = record.marc
  marc.each_by_tag("100") do |tag|
    tag.foreign_object = composer
    x = tag.fetch_first_by_tag("0")
    xnode = x.deep_copy
    x.destroy_yourself
    xnode.foreign_object=composer
    xnode.content = composer.id
    tag.add(xnode)
    tag.resolve_externals
    modified = true
  end
  record.save if modified
}

maintenance.execute process

