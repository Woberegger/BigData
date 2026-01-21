create 'people', 'id', 'property'
# ensure the table is enabled, otherwise this might look like a hanging hbase
enable 'people'
# Wait until all regions are assigned
# This ensures no client-side hang during the first Put - sleep at least 1 second
while ! is_enabled 'people'
  sleep 1
  puts "Waiting for records to be inserted ..."
end
puts "Table 'people' ready. Inserting data..."
 
# Insert data safely
put 'people', 'row1', 'id:email', 'chef@jofre.de'
put 'people', 'row1', 'property:age', '28'
put 'people', 'row2', 'id:name', 'John Doe'
put 'people', 'row2', 'property:job', 'Consultant'
put 'people', 'row2', 'property:age', '31'

get 'people', 'row1'

# if you want to drop a table, you have to call:4
# disable 'people'
# drop 'people'