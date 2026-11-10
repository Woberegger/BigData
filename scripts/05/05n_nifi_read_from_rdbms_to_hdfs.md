# BigData05 - read from RDBMS with Nifi

we will use Nifi to read from MySQL database to Hive

## prepare source and destination tables

switch to `hduser`
```bash
su - hduser
```

create hive destination table as external table. As Nifi uses binary [Parquet](https://de.wikipedia.org/wiki/Apache_Parquet) as output format, this has to be told to Hive.

```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger <<!
DROP TABLE IF EXISTS StudentsNifi;
-- the entry_date column should be string, as date fields cannot easily be mapped between MySQL and hive
CREATE EXTERNAL TABLE IF NOT EXISTS StudentsNifi (
    id         INT,
    first_name STRING,
    last_name  STRING,
    entry_date STRING,
    course     STRING
)
STORED AS PARQUET
LOCATION '/user/hduser/hive_external/students';
!

hdfs dfs -mkdir -p /user/hduser/hive_external/students
# check, if necessary
hdfs dfs -chmod 777 /user/hduser/hive_external/students
```

fill some test data into MySQL source table `studentsMySQL`:
```bash
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
mysql --ssl=FALSE -u $MYSQLUSER -D $DATABASE_NAME  -h datanode1 -P 13306 --password=$MYSQL_PASSWD < ~/BigData/scripts/05/insertstudentsMySQL.sql
```

## configure Nifi in Web GUI

then we need to configure NiFi using Web GUI on port 8999/nifi:

> you can skip all those steps, when loading xml file scripts/05/MySqlToHive_NifiTemplate.xml via the following icon

![upload existing templatge](image-201.png)

Otherwise continue with the step-by-step guide...

![open configuration screen](images/image-0.png)

add a new controller service:<br>

![add controller service](images/image-1.png)

of type DBCPConnectionPool:<br>

![set type of connection pool](images/image-2.png)

rename the pool to a meaningful value:<br>

![set pool name](images/image-3.png)

and set following properties (replace `swd00` by e.g. `itm01` or `swd01` inside of blue borders and take values in green borders as they are):<br>

![set connection properties](images/image-4.png)

press the `flash` icon to enable the service:<br>

![enable service](images/image-5.png)

add a new processor by dragging the following icon to the canvas board:<br>

![add processor](images/image-6.png)

![QueryDatabaseTable processor](images/image-7.png)

set at least following values in the processor's properties (field "Maximum-value Columns" is used to find new inserts basing on ascending `id`)<br>
> IMPORTANT: table names, database names etc. are case sensitive !!!

![Processor properties](images/image-8.png)

then add processor to write the data from MySQL to HDFS:<br>

![ConvertRecord processor](images/image-9.png)

and set the proper values for record reader and writer as below (you can keep the default names or also give them meaningful values):<br>

![RecordReaderWriter](images/image-10.png)

add the end you should see the following 3 services, all 3 enabled:<br>

![enabled controller services](images/image-11.png)

add a processor to write to HDFS:<br>

![add PutHDFSProcessor](images/image-12.png)

and configure hadoop config files and the proper hive external directory:<br>

![HDFS put settings](images/image-13.png)

and then tell Nifi to end the processing after this step (other steps might also terminate in case of failure):<br>

![terminate after last process](images/image-14.png)

--then create an UpdateAttribute processor to configure target file names <br>
--![UpdateAttribute](images/image-15.png)

in the end your screen should look as below and pressing the `Play` button of the flow should show success:<br>

![start Nifi flow](images/image-16.png)

if all went well, you should see in the web GUI, that some bytes were read and written<br>
and you should find a non-empty file in the HDFS target directory:

```bash
hdfs dfs -ls /user/hduser/hive_external/students
```

and then check the content of the destination table, which should find all records:<br>
```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger <<!
select * from StudentsNifi;
!
```

the graphical configuration can be exported using a template (IMPORTANT: the complete NiFi Flow should be shown - and not only one step):<br>

![create template](image-17.png)

and then download the created template:

![download template](image-18.png)
## additional task: test incremental synchronisation

when inserting some additional records to source table with higher IDs, the cyclic refresh should find those

```bash
export MYSQL_USER=$(echo ${HOSTNAME//bigdata})
export MYSQL_PASSWD=$MYSQL_USER
export DATABASE_NAME=$MYSQL_USER
mysql --ssl=FALSE -u $MYSQLUSER -D $DATABASE_NAME  -h datanode1 -P 13306 --password=$MYSQL_PASSWD <<!
INSERT INTO studentsMySQL VALUES (62, 'Tony', 'Anderson', '20221214', 'SWD');
INSERT INTO studentsMySQL VALUES (63, 'Tim', 'Black', '20221215', 'SWD');
INSERT INTO studentsMySQL VALUES (64, 'Jack', 'Ramez', '20230109', 'ITM');
INSERT INTO studentsMySQL VALUES (65, 'Paul', 'Summer', '20230110', 'SWD');
INSERT INTO studentsMySQL VALUES (66, 'James', 'Green', '20230111', 'SWD');
COMMIT;
!
```

after next run cycle you should see the ID being a higher value then 56, i.e. 66 after the following inserts:<br>

![maximum ID value](images/image-101.png)