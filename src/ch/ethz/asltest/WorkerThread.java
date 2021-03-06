package ch.ethz.asltest;
import java.io.IOException;
import java.net.Socket;
import java.nio.CharBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Iterator;

import java.util.Queue;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.atomic.AtomicLong;

/**
 * @author arinaldi
 * This class implements the worker thread, that takes a single request out of the queue, parse it and process it
 * following different path according to its type. In case of a Set request, it is replicated to all the servers 
 * and then all the responses are fetched. If the request is a Get, it is simply forwarded to one of the servers
 * while if it is a multi-get we distinguish two cases. If sharding is enabled, the message is splitted in smaller 
 * requests and these forwarded to the servers accordingly, while if it is not enabled, all the gets are sent to 
 * one single server. Lastly, when the responses have been collected, the worker thread sends the reply to the client.
 */
public class WorkerThread implements Runnable{
	public ArrayList<ServerHandler> servers = new ArrayList<>();
	private String input;
	private LinkedBlockingQueue<Job> queue;
	public final int myNumber;
	Job currentJob;
	ArrayList<String> replies = new ArrayList<>();
	Iterator<String> values;
	String requestType;
	int numOfRecipients;
	ArrayList<Socket> sockets;
	String[][] parts;
	public ArrayList<String> unproperRequests = new ArrayList<>();
	public static int numOfMisses = 0;
	long sendTime;
	long receiveTime;
	ServerHandler recipient;
	int requestsPerServer;
	int remainingRequests;
	String message;
	String finalReply;
	SocketChannel socketChannel;
	CharBuffer buffer;
	String type = null;
    private int serverCount = 0;
	int miss = 0;
	
	public int numOfGets = 0;
	public int numOfSets = 0;
	public int numOfMultiGets = 0;

	public ArrayList<String> times = new ArrayList<>();
	public static AtomicLong numOfRequests = new AtomicLong(0);
	public float myNumOfRequests = 0;
	public long resetTime;
	
	Long queueTime;
	Long workerTime;
	Long serviceTime;
	Long responseTime;
	Long processingTime;
	Long timeInSystem;
	
	long pollTime;
	public ArrayList<String> myThroughput = new ArrayList<>();
	
	/**
	 * @param number the ID of the worker thread
	 * @param parts the address and ports of the servers
	 * @param queue the network queue from where to take the requests
	 */
	public WorkerThread(int number, String[][] parts, LinkedBlockingQueue<Job> queue) {
		this.parts = parts;
		this.queue = queue;
		myNumber = number;
		for(int i = 0; i < parts.length; i++){
			try {
				int port = Integer.parseInt(parts[i][1]);
				Socket socket = new Socket(parts[i][0], port);
				ServerHandler sh = new ServerHandler(socket);
				servers.add(sh);
			} catch (IOException e){
				e.printStackTrace();
			}
			
		}
	}

	@Override
	public void run() {

		try {
			do{
			
				currentJob = queue.take();
				pollTime = System.nanoTime();
				if(currentJob != null) {
					queueTime = pollTime - currentJob.queueEntranceTime;
	
					this.input = currentJob.getInputObject();
					
					if(this.input.equals("EXIT")) {
						for(ServerHandler sh : servers) {
							try {
								sh.getSocket().close();
							} catch (IOException e) {
								System.out.println("Error closing worker thread - server socket");
							}
						}
						return;
					}
					requestType = this.input.substring(0, 3);
					
					switch(requestType) {
					case "get":
						sendGetRequest();
						break;
					case "set":
						sendSetRequest();
						break;
					default:
						unproperRequests.add(input);
						sendBack(currentJob.getClient(), "ERROR\r\n");
						break;
					}
				}
			}while(true);
		} catch (InterruptedException e1) {
		}
	}
	
	/**
	 * If the request is a Set it is forwarded to all the servers and
	 * finally the response sent back to the client
	 */
	private void sendSetRequest() {
		numOfSets++;
		type = "0";
		numOfRecipients = servers.size();
		for(ServerHandler s : servers) {
			s.send(this, input);
		}
		sendTime = System.nanoTime();

		workerTime = sendTime - pollTime;
		
		for(ServerHandler s : servers) {
			String ricevuto = s.receive();
			replies.add(ricevuto);
		}
		receiveTime = System.nanoTime();
		processingTime = receiveTime - sendTime;
		
		
		for(String reply : replies) {
			if(!("STORED".equals(reply))) {
				unproperRequests.add(reply);
				sendBack(currentJob.getClient(), reply);
				replies.clear();
				return;
			}
		}
		sendBack(currentJob.getClient(), "STORED");
		replies.clear();
		
	}

	
	/**
	 * In case of a get request or multi-get with no sharding, the message is sent only to one server
	 * while in case of multi-get with sharding the request is split into multiple parts and forwarded 
	 * to the servers. Lastly, the response is sent back to the client.
	 */
	public void sendGetRequest() {
		String[] requests = this.input.substring(4, this.input.length()).split(" "); 
		
		if(requests.length <= 1 || !(MyMiddleware.readSharded)){
			numOfRecipients = 1;
			recipient = servers.get(loadBalance());

			recipient.send(this, input);
			sendTime = System.nanoTime();

			workerTime = sendTime - pollTime;

			
			if(requests.length <= 1) {
				numOfGets++;
				type= "10";
			}
			else {
				numOfMultiGets++;
				type = requests.length+"";
			}
			
			
			String reply = recipient.receive();
			receiveTime = System.nanoTime();
			processingTime = receiveTime - sendTime;
			
			int hit = 0;
			hit += reply.split("VALUE").length - 1;
			miss += requests.length-hit;

			if(!(reply.endsWith("END"))) {
				unproperRequests.add(reply);
				sendBack(currentJob.getClient(), reply);
				return;
			}
			sendBack(currentJob.getClient(), reply);

		}
		else {
			numOfMultiGets++;
			type = requests.length+"";
			numOfRecipients = servers.size();
			requestsPerServer = requests.length / servers.size();
			remainingRequests = requests.length % servers.size() ;
			
			//The worker thread sends a number of requests to each server equal to requestsPerServer 
			//and at most requestsPerServer + remainingRequests
			
			for(int i = 0; i < servers.size(); i++) {
				message = requestType;
				for(int j = 0; j < requestsPerServer; j++){
					message += " ";
					message += requests[requestsPerServer*i+j];
					if(i < remainingRequests) {
						message += " ";
						message += requests[requests.length - remainingRequests + i];
					}
				}
				servers.get(i).send(this, message);
			}
			sendTime = System.nanoTime();

			workerTime = sendTime - pollTime;

			int hit = 0;
			for(ServerHandler s : servers) {
				String ricevuto = s.receive();
				hit += ricevuto.split("VALUE").length - 1;
				replies.add(ricevuto);
			}
			receiveTime = System.nanoTime();
			processingTime = receiveTime - sendTime;

			miss += requests.length-hit;
			
			finalReply  = "";
			for(String reply : replies) {
				if(!(reply.endsWith("END"))) {
					unproperRequests.add(reply);
					sendBack(currentJob.getClient(), reply);
					replies.clear();
					return;
				}
				else {
					reply = reply.substring(0, reply.length() - 3);
					finalReply += reply;
				}
			}
			finalReply += "END";
			sendBack(currentJob.getClient(), finalReply);
			replies.clear();

		}
		
	}
	
	/**
	 * This is where the message is sent back to the client that made that request
	 * @param key the client Selection Key
	 * @param message the response message
	 */
	public void sendBack(SelectionKey key, String message) {
		socketChannel = (SocketChannel) key.channel(); 
		message += "\r\n";
		buffer = CharBuffer.wrap(message);
		while (buffer.hasRemaining()) {
			try {
				socketChannel.write(Charset.defaultCharset().encode(buffer));
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
		Long x = System.nanoTime();
		serviceTime = x - pollTime;
		responseTime = x - currentJob.queueEntranceTime;
		timeInSystem = x - currentJob.timeOfArrival;
		
		times.add(myNumber + "\t" + type + "\t" + queueTime + "\t" + workerTime +"\t" + processingTime +"\t" + serviceTime +"\t" + responseTime +"\t" + timeInSystem );
		numOfRequests.incrementAndGet();
		myNumOfRequests++;
	}
	
	
	/**
	 * This is the function that is used to balance the load to the servers in case of a get or multi-get without sharding
	 * @return the index of the server to which the worker threads have to send the message
	 */
	public int loadBalance() {
		serverCount++;
		serverCount = (serverCount) % (servers.size());
		return serverCount;
	}
}