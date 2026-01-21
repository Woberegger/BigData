# Verifiziere nochmal, ob Flume funktioniert (bitte auch achten, dass dfs und yarn laufen)

su - hduser
# for the Twitter agent
cat >$FLUME_HOME/conf/twitter_agent.conf <<!
# Naming the components on the current agent. 
TwitterAgent.sources = Twitter 
TwitterAgent.channels = MemChannel 
TwitterAgent.sinks = HDFS
  
# Describing/Configuring the source 
TwitterAgent.sources.Twitter.type = org.apache.flume.source.twitter.TwitterSource
TwitterAgent.sources.Twitter.consumerKey = <Your OAuth consumer key>
TwitterAgent.sources.Twitter.consumerSecret = <Your OAuth consumer secret>
TwitterAgent.sources.Twitter.accessToken = <Your OAuth consumer key access token>
TwitterAgent.sources.Twitter.accessTokenSecret = <Your OAuth consumer key access token secret>
TwitterAgent.sources.Twitter.keywords = Tennis,ATP,Djokovic,Nadal,Federer,Thiem,Ofner
  
# Describing/Configuring the sink 

TwitterAgent.sinks.HDFS.type = hdfs 
TwitterAgent.sinks.HDFS.hdfs.path = hdfs://namenode:9000/user/twitter_data/
TwitterAgent.sinks.HDFS.hdfs.fileType = DataStream 
TwitterAgent.sinks.HDFS.hdfs.writeFormat = Text 
TwitterAgent.sinks.HDFS.hdfs.batchSize = 1000
TwitterAgent.sinks.HDFS.hdfs.rollSize = 0 
TwitterAgent.sinks.HDFS.hdfs.rollCount = 10000
TwitterAgent.sinks.HDFS.hdfs.rollInterval = 600 
 
# Describing/Configuring the channel 
TwitterAgent.channels.MemChannel.type = memory 
TwitterAgent.channels.MemChannel.capacity = 10000 
TwitterAgent.channels.MemChannel.transactionCapacity = 1000
  
# Binding the source and sink to the channel 
TwitterAgent.sources.Twitter.channels = MemChannel
TwitterAgent.sinks.HDFS.channel = MemChannel
!
# Weitere Anleitung siehe Folien zu Vorlesung #5