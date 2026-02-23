# BigData04 - Hive commands

## connect to beeline CLI and do necessary initializations
to be executed in new session, after "hiveserver" has been started in another session

depending on whether you use HiveServer or HiveEmbedded, you need to use a different connect string (in Embedded Mode the variable is empty)
```bash
export HIVE_CONNECT_STRING=localhost:10000
```

> **IMPORTANT:**<br>
> - Hive/Beeline Session can be ended by <Ctrl>c.<br>
> - comments in beeline start with `--` (similar to SQL)

do the following only once to connect to beeline, the other blocks are the HiveQL commands:
```bash
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   show databases;
   use default;
```

## Beeline commands
create some tables for tests
```sql
CREATE TABLE IF NOT EXISTS default.employee (
   id int,
   name string,
   age int,
   gender string )
   COMMENT 'Employee Table'
   ROW FORMAT DELIMITED
   FIELDS TERMINATED BY ',';
   --
   show tables;
```

we will later see, that MapReduce jobs are running in the background, when we execute queries - this is because of:<br>
"set hive.execution.engine=mr".

now we will create 2 so-called "external tables" and 2 "internal tables" with the same content,
so that we can demonstrate the difference<br>
```sql
CREATE EXTERNAL TABLE IF NOT EXISTS adresses(
    cust_id INT, first_name STRING,last_name STRING,company_name STRING,address STRING,city STRING,county STRING,state STRING,zip STRING,phone1 STRING,phone2 STRING,email STRING,web STRING)
    COMMENT 'Adresses'
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ','
    STORED AS TEXTFILE
    LOCATION '/user/hduser/hive_external/adr';

CREATE EXTERNAL TABLE IF NOT EXISTS sales(
    cust_id INT,Product_ID STRING,Category STRING,SubCategory STRING,ProductName STRING,Sales DOUBLE,Quantity DOUBLE,Discount  DOUBLE,Profit DOUBLE)
    COMMENT 'Sales'
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY ';'
    STORED AS TEXTFILE
    LOCATION '/user/hduser/hive_external/sales';
```

and now we generate identical INTERNAL tables with identical content (under /user/hive/warehouse)
```sql
CREATE TABLE IF NOT EXISTS adresses_internal(
    cust_id INT, first_name STRING,last_name STRING,company_name STRING,address STRING,city STRING,county STRING,state STRING,zip STRING,phone1 STRING,phone2 STRING,email STRING,web STRING)
    COMMENT 'Adresses managed as internal table';
CREATE TABLE IF NOT EXISTS sales_internal(
    cust_id INT,Product_ID STRING,Category STRING,SubCategory STRING,ProductName STRING,Sales DOUBLE,Quantity DOUBLE,Discount  DOUBLE,Profit DOUBLE)
    COMMENT 'Sales managed as internal table';

INSERT OVERWRITE TABLE adresses_internal SELECT * FROM adresses;
INSERT OVERWRITE TABLE sales_internal SELECT * FROM sales;
```

finally we do some joins and run the word-count task in HiveQL (similar to what we did in Java MapReduce implementation)
```sql
-- the simpliest join only involves 1 table (no matter, if external or internal)
select s.cust_id, sum(s.sales) as summe from sales s group by cust_id limit 20;
select s.cust_id, sum(s.sales) as summe from sales_internal s group by cust_id limit 20;
```

if the following command ends with an exception (and the exception also happens when using the internal tables instead of the external ones),
then you need to check if in hive-site.xml the property hive.auto.convert.join is set to false - then it should work
```sql
select a.last_name, sum(s.sales) as summe from sales s inner join adresses a on s.cust_id = a.cust_id group by a.last_name order by summe asc;
```

WordCount (INPATH is the path inside of HDFS)
```sql
DROP TABLE IF EXISTS docs;
DROP TABLE IF EXISTS word_counts;

CREATE TABLE docs (line STRING);
LOAD DATA INPATH '/input/Bibel.txt' OVERWRITE INTO TABLE docs;

CREATE TABLE IF NOT EXISTS word_counts AS
SELECT word, count(1) AS count FROM
 (SELECT explode(split(line, ' ')) AS word FROM docs) temp
GROUP BY temp.word
ORDER BY temp.word;
```

and that should find the first 100 records, descending by occurrence
```sql
SELECT * FROM word_counts ORDER BY count DESC, Word ASC LIMIT 100;
```