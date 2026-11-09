# BigData05 - read from RDBMS with Nifi

we will use Nifi to read from MySQL database to Hive

switch to `hduser`
```bash
su - hduser
```

create hive destination table as external table. As Nifi uses binary [Parquet](https://de.wikipedia.org/wiki/Apache_Parquet) as output format, this has to be told to Hive.

```bash
export HIVE_CONNECT_STRING=localhost:10000
beeline --verbose -u jdbc:hive2://$HIVE_CONNECT_STRING scott tiger <<!
CREATE EXTERNAL TABLE StudentsNifi (
    id        INT,
    name      STRING,
    semester  INT,
    course    STRING
)
STORED AS PARQUET
LOCATION '/user/hduser/hive_external/studentsNifi';
!
# check, if necessary
hdfs dfs -chown nifi /user/hduser/hive_external/studentsNifi
```

then we need to configure NiFi using Web GUI on port 8999/nifi:

![open configuration screen](image-0.png)

add a new controller service:<br>

![add controller service](image-1.png)

of type DBCPConnectionPool:<br>

![set type of connection pool](image-2.png)

rename the pool to a meaningful value:<br>

![set pool name](image-3.png)

and set following properties (replace `swd00` by e.g. `itm01` or `swd01` inside of blue borders and take values in green borders as they are):<br>

![set connection properties](image-4.png)

press the `flash` icon to enable the service:<br>

![enable service](image-5.png)