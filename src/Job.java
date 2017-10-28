import java.nio.channels.SelectionKey;

public class Job {
	private String inputObject;
	private SelectionKey client;
	
	public Job(String inputObject, SelectionKey client) {
		this.inputObject = inputObject;
		this.client = client;
	}

	public SelectionKey getClient() {
		return client;
	}

	public String getInputObject() {
		return inputObject;
	}
	
	
}
