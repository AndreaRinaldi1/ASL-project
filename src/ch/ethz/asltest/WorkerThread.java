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
	
	public int loadBalance() {
		serverCount++;
		serverCount = (serverCount) % (servers.size());
		return serverCount;
	}
}