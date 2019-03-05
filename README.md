# Multilingual KSQL UDF Experiment
A POC for multilingual (Python, Javascript, Ruby, etc) UDFs in KSQL

## Background
While doing research for my upcoming talk at Kafka Summit London, I wanted to see if I could implement multilingual UDFs in KSQL. I was able to get this working with the help of GraalVM, but the effort is still a __work in progress__ and I'd like to coordinate with others who are either actively working on this, or who have feedback.

The actual work is happening in [this branch][my-branch], and you're free to build that branch locally + run your own tests without the aid of the `magicalpipelines/ksql-multilingual-udfs` Docker image (__note:__ you'll need to run KSQL using GraalVM for multilingual UDFs to work). The reason I created this Docker image is so that others who don't have a lot of experiencing building the KSQL project / sub-projects can test this functionality out very easily. Also, those who don't have the patience to install GraalVM can instead just use this image as described in this doc.

___

___IMPORTANT NOTE:___ the work here should be considered experimental and incomplete. I will likely submit a KLIP that formally describes the potential syntax we may want to use for multilingual UDFs, and all of the other features / changes that we may want to include as part of this work.

___

[my-branch]: https://github.com/confluentinc/ksql/compare/master...mitch-seymour:feature-multilingual-udfs

### Table of Contents  
- [Prerequisites](#prerequisites)
- [Demo setup](#demo-setup)  
- [Multilingual UDF demos](#multilingual-udf-demos)
  - [Javascript](#javascript)
  - [Python](#python)
  - [Ruby](#ruby)


# Prerequisites
- a running Kafka cluster
- kafkacat (optional)

# Demo Setup
- ### Start the KSQL server

    ```bash
    # tab 1
    $ docker run --net=host \
        -e BOOTSTRAP_SERVERS=localhost:9092 \
        -ti magicalpipelines/ksql-multilingual-udfs:latest
     ```
 
- ### Start the KSQL CLI

     ```bash
     # tab 2
    $ docker run --net=host \
        -ti magicalpipelines/ksql-multilingual-udfs:latest \
        ksql
    ```
    
    Once the CLI has started, set the following config:
    
    ```sql
    ksql> SET 'auto.offset.reset' = 'earliest';
    ```
 
 - ### Create a dummy topic
   Create a dummy topic named `api_logs`. If your cluster is configured to auto created topics, then you can skip to the next step, which will create the topic once you produce some dummy data.

 - ### Produce dummy data
 
    ```bash
    $ echo '{"endpoint": "about.html", "status_code": 200}' |  kafkacat -P -b localhost:9092 -t api_logs && \
      echo '{"endpoint": "index.html", "status_code": 200}' |  kafkacat -P -b localhost:9092 -t api_logs && \
      echo '{"endpoint": "contact.php", "status_code": 404}' |  kafkacat -P -b localhost:9092 -t api_logs
    ```
 
 - ### In the CLI, create a stream to read from our dummy topic.
     
     ```sql
     ksql> CREATE STREAM api_logs (endpoint VARCHAR, status_code INT)
           WITH (kafka_topic='api_logs', value_format='JSON');
    ```
  

# Multilingual UDF demos
Now, in the CLI, run the following commands to try out multilingual UDFS :)

## Javascript
Create a Javascript UDF with the following command:
```sql
ksql> CREATE OR REPLACE FUNCTION STATUS_MAJOR(status_code INT) 
RETURNS VARCHAR
LANGUAGE JAVASCRIPT AS $$
(code) => code.toString().charAt(0) + 'xx'
$$ 
WITH (author='Mitch Seymour', description='js udf example', version='0.1.0');
```

Verify the new UDF exists:

```sql
ksql> DESCRIBE FUNCTION STATUS_MAJOR ;

Name        : STATUS_MAJOR
Author      : 'Mitch Seymour'
Version     : '0.1.0'
Type        : scalar
Jar         : internal
Variations  :

	Variation   : STATUS_MAJOR(INT)
	Returns     : VARCHAR
	Description : 'js udf example'
```

Invoke the new UDF:

```sql
SELECT endpoint, status_code, status_major(status_code)
FROM api_logs ;
```

Verify the output:

```sql
about.html | 200 | 2xx
index.html | 200 | 2xx
contact.php | 404 | 4xx
```

## Python
Create a Python UDF with the following command:
```sql
ksql> CREATE OR REPLACE FUNCTION ENDPOINT_TYPE(endpoint VARCHAR) 
RETURNS VARCHAR
LANGUAGE PYTHON AS $$
lambda endpoint: endpoint.split(".")[1]
$$ 
WITH (author='Mitch Seymour', description='python udf example', version='0.1.0');
```

Verify the new UDF exists:

```sql
ksql> DESCRIBE FUNCTION ENDPOINT_TYPE ;

Name        : ENDPOINT_TYPE
Author      : 'Mitch Seymour'
Version     : '0.1.0'
Type        : scalar
Jar         : internal
Variations  :

	Variation   : ENDPOINT_TYPE(VARCHAR)
	Returns     : VARCHAR
	Description : 'python udf example'
```

Invoke the new UDF. Note: the cold start with Python is a little more noticable than the Javascript UDF. But it should only incurred when the UDF is first instantiated.

```sql
SELECT endpoint, endpoint_type(endpoint)
FROM api_logs ;
```

Verify the output:

```sql
about.html | html
index.html | html
contact.php | html
```

## Ruby
Create a Ruby UDF with the following command:
```sql
ksql> CREATE OR REPLACE FUNCTION REVERSE(endpoint VARCHAR) 
RETURNS VARCHAR
LANGUAGE RUBY AS $$
lambda { |x| x.reverse }
$$ 
WITH (author='Mitch Seymour', description='ruby udf example', version='0.1.0');
```

Verify the new UDF exists:

```sql
ksql> DESCRIBE FUNCTION REVERSE ;

Name        : REVERSE
Author      : 'Mitch Seymour'
Version     : '0.1.0'
Type        : scalar
Jar         : internal
Variations  :

	Variation   : REVERSE(VARCHAR)
	Returns     : VARCHAR
	Description : 'ruby udf example'
```

Invoke the new UDF:

```sql
SELECT endpoint, reverse(endpoint)
FROM api_logs ;
```

Verify the output:

```sql
about.html | lmth.tuoba
index.html | lmth.xedni
contact.php | php.tcatnoc
```
