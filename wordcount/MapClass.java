package at.fhj;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Mapper;

/**
 * Map Class which extends MaReduce.Mapper class
 * Map is passed a single line at a time, it splits the line based on space
 * and generated the token which are output by map with value as one to be consumed
 * by reduce class
 * @author Raman
 */
public class MapClass extends Mapper<LongWritable, Text, Text, IntWritable>{
	 
	private final static IntWritable one = new IntWritable(1);
    private Text word = new Text();
    /** map function of Mapper parent class takes a line of text at a time
        splits to tokens and passes to the context as word along with value as one  */
	@Override
	protected void map(LongWritable key, Text value,
			Context context)
			throws IOException, InterruptedException {
		/** tell mapper how to interpret and split the input */
		String line = value.toString();
		StringTokenizer st = new StringTokenizer(line," ");
		/** special keyword "one" tell to add 1 occurance of that word to that key */
		while(st.hasMoreTokens()){
			word.set(st.nextToken());
			context.write(word,one);
		}
	}
}