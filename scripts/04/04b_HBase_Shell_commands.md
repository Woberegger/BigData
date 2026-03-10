# BigData04 - HBase simple table creation and data insertion

Open HBase Shell and create simple tables with data

```bash
hbase shell
```

check for proper hbase prompt, that it does not write any error,<br>
then do the following commands in hbase shell:

```sql
create 'people', 'id', 'property'
```

ensure the table is enabled, otherwise this might look like a hanging hbase
```sql
enable 'people'
```

Wait until all regions are assigned<br>
This ensures no client-side hang during the first Put - sleep at least 1 second
```sql
while ! is_enabled 'people'
  sleep 1
  puts "Waiting for records to be inserted ..."
end
puts "Table 'people' ready. Inserting data..."
```

Insert data safely into hbase, then select the first row
```sql
put 'people', 'row1', 'id:email', 'chef@jofre.de'
put 'people', 'row1', 'property:age', '28'
put 'people', 'row2', 'id:name', 'John Doe'
put 'people', 'row2', 'property:job', 'Consultant'
put 'people', 'row2', 'property:age', '31'

get 'people', 'row1'
```

**Don't do this now:** if you want to drop a table later, you have to call:
```sql
disable 'people'
drop 'people'
```