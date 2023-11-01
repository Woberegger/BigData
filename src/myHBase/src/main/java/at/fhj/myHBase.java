//jars hbase-client-*.jar, hadoop-common-*.jar und hbase-common-*.jar aus /usr/local/HBase/lib ins Projekt importieren
package at.fhj;

import java.io.IOException;
import java.util.List;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Admin;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;
import org.apache.hadoop.hbase.client.Get;
import org.apache.hadoop.hbase.client.Result;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.client.TableDescriptor;
import org.apache.hadoop.hbase.util.Bytes;

public class myHBase {

	public static void main(String[] args) throws IOException, Exception {

		Configuration conf = HBaseConfiguration.create();
		Connection connection = ConnectionFactory.createConnection(conf);

		Table table = connection.getTable(TableName.valueOf("people"));

		// instantiate Get class
		Get g = new Get(Bytes.toBytes("row1"));

		// get the Result object
		Result result = table.get(g);

		// read values from Result class object
		byte[] id = result.getValue(Bytes.toBytes("id"), Bytes.toBytes("email"));
		byte[] property = result.getValue(Bytes.toBytes("property"), Bytes.toBytes("age"));

		System.out.println("name: " + Bytes.toString(id));
		System.out.println("age: " + Bytes.toString(property));

		Admin admin = connection.getAdmin();

		// Getting all the list of tables using HBaseAdmin object
		List<TableDescriptor> tableDescriptor = admin.listTableDescriptors();
		// printing all the table names.
		for (int i = 0; i < tableDescriptor.size(); i++) {
			System.out.println(tableDescriptor.get(i).getTableName());
		}

	}

}