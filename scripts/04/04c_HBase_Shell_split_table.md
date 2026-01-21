# create table with more than 1 column family
create 'people2', 'id', 'property', 'specialdate'
enable 'people2'
# Wait until all regions are assigned
# This ensures no client-side hang during the first Put - sleep at least 1 second
while ! is_enabled 'people2'
  sleep 1
  puts "Waiting for records to be inserted ..."
end
puts "Table 'people2' ready. Inserting data..."

put 'people2', 'row1', 'id:email', 'chef@jofre.de'
put 'people2', 'row1', 'property:age', '28'
put 'people2', 'row1', 'specialdate:birthday', '1999-01-23'
put 'people2', 'row2', 'id:name', 'Rene K.' ''
put 'people2', 'row2', 'property:job', 'Consultant' '2023'
put 'people2', 'row2', 'specialdate:wedding', '03.05.2007'

get 'people2', 'row1'

# create table to split across multiple regions by ID - can be even multiple regions on 1 server - see http://localhost:16010/table.jsp?name=emp
create 'emp', 'id', 'property', SPLITS => ['1', '20']
enable 'emp'
# Wait until all regions are assigned
# This ensures no client-side hang during the first Put - sleep at least 1 second
while ! is_enabled 'emp'
  sleep 1
  puts "Waiting for records to be inserted ..."
end
puts "Table 'emp' ready. Inserting data..."

# list should find all our created tables
list

put 'emp', '1' , 'property:name', 'Scott'
put 'emp', '21' , 'property:name', 'Mark'     
put 'emp', '21' , 'property:gender', 'M'     
put 'emp', '21' , 'property:age', '30'
put 'emp', '21' , 'property:age', '50'

get 'emp', '21'

# show the created regions for our table
list_regions 'emp'

### expected output, when multiple regions exist:
#                   SERVER_NAME |                                            REGION_NAME |  START_KEY |    END_KEY |  SIZE |   REQ |   LOCALITY |
# ----------------------------- | ------------------------------------------------------ | ---------- | ---------- | ----- | ----- | ---------- |
# datanode1,16020,1761465824268 |   emp,,1761465929138.eeedbf3b61495df417f75c074f3583be. |            |          1 |     0 |     0 |        0.0 |
# datanode1,16020,1761465824268 |  emp,1,1761465929138.d9367e8109d374c6149fb2c1450b764b. |          1 |         20 |     0 |     1 |        0.0 |
#  namenode,16020,1761465830925 | emp,20,1761465929138.bf160eaff41db660f12e859c6cbb17db. |         20 |            |     0 |     5 |        0.0 |