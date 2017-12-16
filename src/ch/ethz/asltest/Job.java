package ch.ethz.asltest;
import java.nio.channels.SelectionKey;

public class Job {
	private String inputObject;
	private SelectionKey client;
	public long timeOfArrival;
	public long queueEntranceTime;
	
	public Job(String inputObject, SelectionKey client, long timeOfArrival, long queueEntranceTime) {
		this.inputObject = inputObject;
		this.client = client;
		this.timeOfArrival = timeOfArrival;
		this.queueEntranceTime = queueEntranceTime;
	}

	public SelectionKey getClient() {
		return client;
	}

	public String getInputObject() {
		return inputObject;
	}
	
	
}
