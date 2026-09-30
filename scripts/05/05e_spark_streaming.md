# BigData05 - spark streaming example

show how to use streaming examples with Spark - similar to what we did with Flume before

I have downloaded that example from following link (however you need not do it, you can use the one from github repo)

> see [streaming-programming-guide](https://archive.apache.org/dist/spark/docs/3.5.3/streaming-programming-guide.html#a-quick-example)

## in session #1

do the netcat test

```bash
su - hduser
netcat -lk 44444
```
> enter e.g. `Hello Spark, the word Hello should appear twice`
As soon as you click enter, you should see the output in the 2nd session, no matter if written before or after connection was established

## in session #2
start spark streaming job<br>
(this is a wordcount task, which processes data during streaming, demonstrating the Spark realtime processing function)

```bash
su - hduser
export SPARK_LOCAL_IP=127.0.0.1
$SPARK_HOME/bin/spark-submit ~/BigData/src/spark/network_wordcount.py localhost 44444
```

expected output in session #2:
> 
> -------------------------------------------<br>
> Time: 2026-09-24 12:41:22<br>
> -------------------------------------------<br>
> ('Spark,', 1)<br>
> ('word', 1)<br>
> ('should', 1)<br>
> ('twice', 1)<br>
> ('Hello', 2)<br>
> ('the', 1)<br>
> ('appear', 1)<br>