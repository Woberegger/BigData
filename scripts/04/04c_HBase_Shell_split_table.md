# BigData04 - HBase more specific tables

```bash
hbase shell
```

## table with more than 1 column family

You can see, that we have families "id", "property" and "specialdate" - and that they can be used to store different types of data, e.g. email, age, birthday etc.

```sql
create 'people2', 'id', 'property', 'specialdate'
enable 'people2'
```

Wait again, until all regions are assigned, then insert data and select the first row
```sql
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
```

## table split across multiple regions by ID

create table to split across multiple regions by ID - can be even multiple regions on 1 server - see [](http://<VM-IP>:16010/table.jsp?name=emp)
```sql
create 'emp', 'id', 'property', SPLITS => ['1', '20']
enable 'emp'
```

Wait again, until all regions are assigned

```sql
while ! is_enabled 'emp'
  sleep 1
  puts "Waiting for records to be inserted ..."
end
puts "Table 'emp' ready. Inserting data..."
```

the `list` command should find all our created tables
```sql
list
```

and now we insert the data
```sql
put 'emp', '1' , 'property:name', 'Scott'
put 'emp', '21' , 'property:name', 'Mark'     
put 'emp', '21' , 'property:gender', 'M'     
put 'emp', '21' , 'property:age', '30'
put 'emp', '21' , 'property:age', '50'

get 'emp', '21'
```

show the created regions for our table
```sql
list_regions 'emp'
```

expected output of `list_regions`, when multiple regions exist:
> ----------------------------- | ------------------------------------------------------ | ---------- | ---------- | ----- | ----- | ---------- |
>                   SERVER_NAME |                                            REGION_NAME |  START_KEY |    END_KEY |  SIZE |   REQ |   LOCALITY |
> datanode1,16020,1761465824268 |   emp,,1761465929138.eeedbf3b61495df417f75c074f3583be. |            |          1 |     0 |     0 |        0.0 |
> datanode1,16020,1761465824268 |  emp,1,1761465929138.d9367e8109d374c6149fb2c1450b764b. |          1 |         20 |     0 |     1 |        0.0 |
>  namenode,16020,1761465830925 | emp,20,1761465929138.bf160eaff41db660f12e859c6cbb17db. |         20 |            |     0 |     5 |        0.0 |

As you can see: There are 3 regions, when we have 2 borders, as they always start at -INFINITY and end at +INFINITY.