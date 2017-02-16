scripts = Dir.glob("housekeeping/maintenance/2*.rb")
scripts.sort.each do |script|
  puts "\n"
  puts "--------------------------------------------------------------------------------------------------------------".colorize(:green)
  puts "Executing #{script}".colorize(:green)
  puts "--------------------------------------------------------------------------------------------------------------".colorize(:green)
  system("rails runner #{Rails.root}/#{script}")
  puts "--------------------------------------------------------------------------------------------------------------".colorize(:green)
  puts "\n"
end
 
