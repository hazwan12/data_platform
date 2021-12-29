# Data Platform Quickstart

## Prerequisites
- Docker
- Bash

## Setup

### Alluxio
Alluxio is a data orchestration layer allowing a single access point for data access.
It allows mounting of object stores, hdfs and nfs onto a single access layer.
User access can be managed on the Alluxio using ACLs.

#### Build the docker image
- Navigate into the `alluxio` directory and run the following command
```bash
docker build -f Dockerfile -t data_platform/alluxio:latest .
```
**Ensure the cloud storage credentials are available in the `alluxio` directory**

#### Start Alluxio Image
- Run the below commands in seperate shell clients
- Alluxio Master to be the main coordinator
```bash
bash alluxio-master.sh
```
- Alluxio worker to execute task from master
- More then 1 workers can be spawned
```bash
bash alluxio-worker.sh
```

#### Mount the cloud storage bucket as a nested path
```bash
docker exec -it alluxio-master alluxio fs mount --option fs.gcs.credential.path=credentials.json /lta-datamall gs://lta-datamall/
```

#### Verify that bucket is mounted successfully
```bash
docker exec -it alluxio-master alluxio fs ls /
```

#### Reference for alluxio commands
- https://docs.alluxio.io/os/user/stable/en/operation/User-CLI.html

### Hive
Hive metastore will be used with Presto to serve catalog information such as table schema

#### Enabling interaction with Alluxio
- Below line has to be added into `${HIVE_HOME}/conf/hive-env.sh`
- Jar file can be found in `${ALLUXIO_HOME}/client/` directory
- This allows hive to recognise the `alluxio://` uri
```
export HIVE_AUX_JARS_PATH=${ALLUXIO_HOME}/client/alluxio-2.7.1-client.jar:${HIVE_AUX_JARS_PATH}
```

### Hive configuration setup
- Next edit the `${HIVE_HOME}/conf/hive-site.xml`
- Ensure that the below property is set to the alluxio hostname and port
```xml
<property>
    <name>fs.defaultFS</name>
    <value>alluxio://alluxio-master:19998</value>
</property>
```

### Starting the hive metastore
- To start the hive metastore 2 commands have to be ran
- Command below is to initalise a new metastore
```bash
${HIVE_HOME}/bin/schematool -dbType derby -initSchema
```
- Command below will server the metastore at port 9083
```bash
${HIVE_HOME}/hcatalog/sbin/hcat_server.sh start
```

#### Build the docker image
- Navigate into the `hive` directory and run the following command
```bash
docker build -f Dockerfile -t data_platform/hive:latest . 
```

#### Start Hive Metatstore Image
- Run the below commands in shell client
```bash
bash start-hive.sh
```

### Trino
Trino is a distributed SQL Query engine able to federate access from a variety of data sources.
Some of these sources are :
- MySql
- Postgres
- AWS S3, GCS, Azure Blob
- Alluxio

#### Node Properties
- This property file contains config specific to each node.
- Property is located in `${TRINO_HOME}/etc/node.properties`
- Reference : https://trino.io/docs/current/installation/deployment.html#node-properties
- Below is a minimal property file
```
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
node.data-dir=/var/trino/data
```

#### JVM Config
- This property file contains a list of cli options for launching the JVM
- Property is located in `${TRINO_HOME}/etc/jvm.properties`
- Reference : https://trino.io/docs/current/installation/deployment.html#jvm-config
- Below is a good start jvm config
```
-server
-Xmx16G
-XX:-UseBiasedLocking
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+ExplicitGCInvokesConcurrent
-XX:+ExitOnOutOfMemoryError
-XX:+HeapDumpOnOutOfMemoryError
-XX:-OmitStackTraceInFastThrow
-XX:ReservedCodeCacheSize=512M
-XX:PerMethodRecompilationCutoff=10000
-XX:PerBytecodeRecompilationCutoff=10000
-Djdk.attach.allowAttachSelf=true
-Djdk.nio.maxCachedBufferSize=2000000
```

#### Server config
- This property file contains the config for the Trino Server
- Property is located in `${TRINO_HOME}/etc/config.properties`
- Reference : https://trino.io/docs/current/installation/deployment.html#config-properties
- Below is the config for the standalone server which this guide is using
```
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
query.max-memory=5GB
query.max-memory-per-node=1GB
query.max-total-memory-per-node=2GB
discovery.uri=http://example.net:8080
```

#### Hive config
- This property file contains the config for the hive connector
- Property is located in `${TRINO_HOME}/etc/catalog/hive.properties`
- Reference : https://trino.io/docs/current/connector/hive.html#configuration
- Below is the config for the trino to mount the hive catalog
```
connector.name=hive
hive.metastore.uri=thrift://hive:9083
hive.non-managed-table-writes-enabled=true
```

### Spark
Spark is a multi purpose cluster computing engine.

#### Jars Dependencies
- Jar dependencies of other applications can be added to spark to allow interaction between them
- Jars can be distributed either through
    - `spark-submit --jars <comma seperated list of jar paths>`
    - adding the jars directly to the `${SPARK_HOME}/jars directory`
- In this example the 2 required jars are copied using the latter
    - `${SPARK_HOME}/jars/alluxio-2.7.1-client.jar` Alluxio client jar allows Spark to interact with the Alluxio FS
    - `${SPARK_HOME}/jars/trino-jdbc-367.jar` Trino JDBC connector allows Spark to make a JDBC connection to Trino

#### Build the docker image
- Navigate into the `spark` directory and run the following command
```bash
docker build -f Dockerfile -t data_platform/spark:latest . 
```

#### Start Spark Image
- Run the below commands in shell client
```bash
bash start-spark.sh
```

## Demo
### Connect to Trino DB
- A catalog is equivalent to a connecter
- The catalog name is derived from the `${TRINO_HOME}/etc/catalog/<example>.properties`; `connector.name=` key
```
docker exec -it trino trino --catalog hive --debug
```

### Create a schema for the mounted bucket
- Create a schema to isolate the tables within the bucket
```
CREATE SCHEMA hive.lta_datamall 
WITH (location = 'alluxio://alluxio-master:19998/lta-datamall/');
```

###  Create a table over the 'raw' file in the bucket
- Create a table on top of the file location
- Location can be pointed either
    - directly to the file or
    - the directory where file is located (**Note that if more then 1 file is in a directory, all the files will be considered to be a table**)
```
CREATE TABLE hive.lta_datamall.raw_buses_age_distribution (
    year varchar,
    age varchar,
    number varchar
) WITH (
    external_location = 'alluxio://alluxio-master:19998/lta-datamall/raw/buses_age_distribution',
    format='CSV'
);
```

### Verify Data is Reflected onto Table
- Since the table is pointing to the file location
- Data should appear similar to the structure of the file
```
SELECT * FROM hive.lta_datamall.raw_buses_age_distribution;
```

### Insert data from raw to refined table with Trino
- Create a table over the 'refined' file in the bucket
- Bug in trino where the directory must exists first
```
docker exec -it alluxio-master alluxio fs mkdir /lta-datamall/refined/buses_age_distribution
```

```
CREATE TABLE hive.lta_datamall.buses_age_distribution (
    age VARCHAR,
    number INTEGER,
    year INTEGER
) WITH (
    external_location = 'alluxio://alluxio-master:19998/lta-datamall/refined/buses_age_distribution',
    format='PARQUET',
    partitioned_by = ARRAY['year']
);
```

- Insert the data
```
INSERT INTO hive.lta_datamall.buses_age_distribution
SELECT 
cast(age as varchar), 
cast(number as integer), 
cast(year as integer)
FROM hive.lta_datamall.raw_buses_age_distribution;
```

### Insert data from raw to refined table with Spark

- Read file from alluxio path into DF
```python
df = spark.read.csv("alluxio://alluxio-master:19998/lta-datamall/raw/buses_age_distribution/", header=True, inferSchema=True)
```

- Rewrite file into the refined table path
- Note that partition column has to be last in col order
```python
df.select("age_years", "number", "year")\
    .write.parquet("alluxio://alluxio-master:19998/lta-datamall/refined/buses_age_distribution/", mode="overwrite", partitionBy="year")
```

- Create table on top of the directory
```
CREATE TABLE hive.lta_datamall.buses_age_distribution (
    age VARCHAR,
    number INTEGER,
    year INTEGER
) WITH (
    external_location = 'alluxio://alluxio-master:19998/lta-datamall/refined/buses_age_distribution',
    format='PARQUET',
    partitioned_by = ARRAY['year']
);
```

### Verify refined table
```
SELECT * FROM hive.lta_datamall.buses_age_distribution
```

## References
- https://www.alluxio.io/blog/tutorial-presto-alluxio-hive-metastore-on-your-laptop-in-10-min/
- https://docs.alluxio.io/os/user/stable/en/compute/Presto.html
- https://trino.io/docs/current/installation/deployment.html