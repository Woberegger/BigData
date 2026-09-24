package at.fhj;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.conf.Configured;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.mapreduce.lib.output.TextOutputFormat;
import org.apache.hadoop.util.Tool;
import org.apache.hadoop.util.ToolRunner;

/**
 * The entry point for the WordCount example,
 * which setup the Hadoop job with Map and Reduce Class
 * 
 * @author Raman
 */
public class WordCount extends Configured implements Tool{
	
	/** Main function which calls the run method and passes the args using ToolRunner */
	public static void main(String[] args) throws Exception{
		int exitCode = ToolRunner.run(new WordCount(), args);
		System.exit(exitCode);
	}
 
	/** Run method which schedules the Hadoop Job */
	public int run(String[] args) throws Exception {
		if (2 != args.length) {
			System.err.printf("Usage: %s needs two arguments <input> <output> files\n",
					getClass().getSimpleName());
			return -1;
		}
	
		/** Initialize the Hadoop job and set the jar as well as the name of the Job */
		Configuration conf = new Configuration();
		Job job = Job.getInstance(conf, "my word count");
		job.setJarByClass(WordCount.class);
		
		/** Add input and output file paths to job based on the arguments passed (either OS or HDFS files) */
		FileInputFormat.addInputPath(job, new Path(args[0]));
		FileOutputFormat.setOutputPath(job, new Path(args[1]));

		/** define, in which format the output shall be (could be also binary, map, database, ...) */
		job.setOutputKeyClass(Text.class);
		job.setOutputValueClass(IntWritable.class);
		job.setOutputFormatClass(TextOutputFormat.class);
		
		/** Those methods need to be implemented always - the MapClass and ReduceClass for the job */
		job.setMapperClass(MapClass.class);
		job.setReducerClass(ReduceClass.class);
	
		/** Wait for the job to complete in the background and print if the job was successful or not */
		int returnValue = job.waitForCompletion(true) ? 0:1;
		
		if(job.isSuccessful()) {
			System.out.println("Job was successful");
		} else if(!job.isSuccessful()) {
			System.out.println("Job was not successful");			
		}
		
		return returnValue;
	}
}
