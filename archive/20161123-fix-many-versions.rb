# encoding: UTF-8
puts "Delete the unused versions after the 774 fix"

# Select the list of ids. We want to keep the FIRST generated version for each record
# and delete the others. We do it in two steps as mysql does not seem happy to have a delete
# with a subquery
query = 'select id from versions where id not in (select min(id) as minid from versions where created_at > "2016-11-16" and whodunnit is null and created_at < "2016-11-16 08:23:23" group by item_id) and created_at > "2016-11-16" and whodunnit is null and created_at < "2016-11-16 08:23:23";'

rec = ActiveRecord::Base.connection.execute(query)

# should be 1154
ap rec.count
ids = rec.each.map {|r| r[0]}

# delete them
delete_query = "delete from versions where id in (#{ids.join(",")})"
rec = ActiveRecord::Base.connection.execute(delete_query)
