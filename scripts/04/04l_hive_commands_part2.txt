# auszuführen in neuer Session, nachdem in anderer Session "hiveserver" gestartet wurde

# Abhängig davon, ob man Hiveserver oder HiveEmbedded verwendet, ist unterschiedlicher connect-String zu verwenden (bei Embedded Mode ist die Variable leer)
export HIVE_CONNECT_STRING=localhost:10000

# Hive Session beenden durch <Ctrl>c.
# Kommentare in beeline starten mit '--'

# testweise Tabellen anlegen
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger
   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   show databases;
   use default;
   -- testweise mal eine Tabelle anlegen
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

   -- HIVE Import & Join ---
   -- man sieht auch schön, dass im Hintergrund MapReduce Jobs laufen, da wir "set hive.execution.engine=mr" setzen.

   set hive.execution.engine=mr;
   set hive.metastore.warehouse.dir;
   show databases;
   show tables;
   use default;

-- diese 2 sind sogenannte "external tables"
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
    
-- und dann legen wir internal tables mit denselben Inhalten an (die werden unter /user/hive/warehouse angelegt)
CREATE TABLE IF NOT EXISTS adresses_internal(
    cust_id INT, first_name STRING,last_name STRING,company_name STRING,address STRING,city STRING,county STRING,state STRING,zip STRING,phone1 STRING,phone2 STRING,email STRING,web STRING)
    COMMENT 'Adresses managed as internal table';
CREATE TABLE IF NOT EXISTS sales_internal(
    cust_id INT,Product_ID STRING,Category STRING,SubCategory STRING,ProductName STRING,Sales DOUBLE,Quantity DOUBLE,Discount  DOUBLE,Profit DOUBLE)
    COMMENT 'Sales managed as internal table';

INSERT OVERWRITE TABLE adresses_internal SELECT * FROM adresses;
INSERT OVERWRITE TABLE sales_internal SELECT * FROM sales;

-- die einfache Abfrage auf nur 1 Tabelle (jeweils auf externe bzw. interne Tabelle)
select s.cust_id, sum(s.sales) as summe from sales s group by cust_id limit 20;
select s.cust_id, sum(s.sales) as summe from sales_internal s group by cust_id limit 20;

-- wenn der folgende Befehl auf Fehler läuft (und es passiert auch, wenn man die internen Tabellen statt den externen verwendet),
-- dann muss man prüfen, ob in hive-site.xml das Property hive.auto.convert.join auf false gesetzt wurde - dann sollte es funktionieren
select a.last_name, sum(s.sales) as summe from sales s inner join adresses a on s.cust_id = a.cust_id group by a.last_name order by summe asc;

--- WordCount (der INPATH ist in Pfad innerhalb von hdfs) ---

DROP TABLE IF EXISTS docs;
DROP TABLE IF EXISTS word_counts;

CREATE TABLE docs (line STRING);
LOAD DATA INPATH '/input/Bibel.txt' OVERWRITE INTO TABLE docs;

CREATE TABLE IF NOT EXISTS word_counts AS
SELECT word, count(1) AS count FROM
 (SELECT explode(split(line, ' ')) AS word FROM docs) temp
GROUP BY temp.word
ORDER BY temp.word;

-- und das sollte die ersten 100 records finden, absteigend nach Vorkommen
SELECT * FROM word_counts ORDER BY count DESC, Word ASC LIMIT 100;