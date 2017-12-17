package ch.ethz.asltest;
import java.nio.channels.SelectionKey;

/**
 * This class provide the structure for the creation of the requests object that the net thread puts
 * in the queue and that will be taken out and processed by the worker threads
 * @author arinaldi
 */
public class Job {
	private String inputObject;
	private SelectionKey client;
	public long timeOfArrival;
	public long queueEntranceTime;
	
	/**
	 * @param inputObject the request body
	 * @param client the client that sent the request
	 * @param timeOfArrival the time in which the client submitted the request to the middleware
	 * @param queueEntranceTime the time the net thread put the Job into the queue
	 */
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
