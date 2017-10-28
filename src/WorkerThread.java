import java.io.IOException;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Random;

public class WorkerThread implements Runnable{
	private ArrayList<ServerHandler> servers = new ArrayList<>();
	private String input;
	private Queue<Job> queue;
	private final int myNumber;
	Job currentJob;
	ArrayList<String> replies = new ArrayList<>();
	Iterator<String> values;
	ArrayList<String> unproperRequests = new ArrayList<>();
	String requestType;
	int numOfRecipients;
	ArrayList<Socket> sockets;
	String[][] parts;
	
	public WorkerThread(int number, String[][] parts, Queue<Job> queue) {
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
		int count = 0;
		
		while(true){
			currentJob = null;
			currentJob = queue.poll();
			if(currentJob != null) {
				this.input = currentJob.getInputObject();
				count++;
				System.out.println("WorkerThread " + myNumber + " input " + input);
	
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
					break;
				}
					
			}
		}
	}
	
	private void sendSetRequest() {
		numOfRecipients = servers.size();
		for(ServerHandler s : servers) {
			s.send(this, input);
		}
			
		
		for(ServerHandler s : servers) {
			String ricevuto = s.receive();
			replies.add(ricevuto);
		}
		
		/*
		while(replies.size() < servers.size()) {
			synchronized(this) {	
				try {
					wait();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
			}
		}
		*/
		
		//values = replies.iterator();
		for(String reply : replies) {
			//String reply = values.next();
			if(!("STORED".equals(reply))) {
				sendBack(currentJob.getClient(), reply);
				replies.clear();
				return;
			}
		}
		sendBack(currentJob.getClient(), "STORED");
		replies.clear();
		
	}

	public void sendGetRequest() {
		
		Map<ServerHandler, String> requestsForServers = new HashMap<>(); //questa mappa mi serve perche quando mando una multiget
		//sharded allora un server mi puo ritornare le risposte a piu di una richiesta e quindi mappo le richieste alle 
		//risposte e alla fine concateno le risposte in base all'ordine delle richieste nella multiget( faccio il get
		//prendendo le richieste dall'array) e le rimando al client (devo controllare anche che non ci siano errori)
		String[] requests = this.input.substring(4, this.input.length()).split(" "); // questo array mi serve per 
		//avere le richieste splittate, cosi posso sapere quante sono e posso suddividerle tra i server, 
		//devo anche salvarle come chiavi nella mappa cosi dopo posso rimandare le risposte in ordine al client
		if(requests.length <= 1 || !(MyMiddleware.readSharded)){
			numOfRecipients = 1;
			ServerHandler recipient = servers.get(MyMiddleware.loadBalance());

			recipient.send(this, input);
			
			/*while(replies.size() < numOfRecipients) {
				synchronized(this) {	
					try {
						wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
			}*/
			replies.add(recipient.receive());
			
			values = replies.iterator();
			while(values.hasNext()) {
				String reply = values.next();
				if(!(reply.endsWith("END"))) {
					sendBack(currentJob.getClient(), reply);
					replies.clear();
					return;
				}
			}
			sendBack(currentJob.getClient(), replies.get(0));
			replies.clear();
		}
		else {
			numOfRecipients = servers.size();
			int requestsPerServer = requests.length / servers.size();
			int remainingRequests = requests.length % servers.size() ;
			
			for(int i = 0; i < servers.size(); i++) {
				String message = requestType;
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
			
			for(ServerHandler s : servers) {
				String ricevuto = s.receive();
				replies.add(ricevuto);
			}
			
			/*while(replies.size() < numOfRecipients) {
				synchronized(this) {	
					try {
						wait();
					} catch (InterruptedException e) {
						e.printStackTrace();
					}
				}
			}*/
			
			
			String finalReply  = "";
			values = replies.iterator();
			while(values.hasNext()) {
				String reply = values.next();
				if(!(reply.endsWith("\r\nEND\r\n"))) {
					sendBack(currentJob.getClient(), reply);
					replies.clear();
					return;
				}
				else {
					reply = reply.substring(0, reply.length() - 5);
					finalReply += reply;
					//finalReply.replaceAll("\r\nEND\r\n", "");
				}
			}
			finalReply += "END\r\n";
			sendBack(currentJob.getClient(), finalReply);
			replies.clear();

		}
		
	}
	
	
	public void receive(String response) {
		 //provare a togliere questo sync o racchiudere solo notify
		synchronized (replies) {
			replies.add(response + "\r\n");
		}
		if(replies.size() == numOfRecipients) {	
			synchronized (this) {
				notify();
			}
		}
	}
	
	public void sendBack(SelectionKey key, String message) {
		SocketChannel socketChannel = (SocketChannel) key.channel(); 
		System.out.println("WorkerThread " + myNumber + " output " + message);
		// write some data into the channel
		message += "\r\n";
		CharBuffer buffer = CharBuffer.wrap(message);
		while (buffer.hasRemaining()) {
			try {
				socketChannel.write(Charset.defaultCharset().encode(buffer));
			} catch (IOException e) {
				e.printStackTrace();
			}
		
		}
		//CharBuffer buffer = CharBuffer.wrap(message);
		/*while (buffer.hasRemaining()) {
			try {
				socketChannel.write(Charset.defaultCharset().encode(buffer));
			} catch (IOException e) {
				e.printStackTrace();
			}
		
		}*/
	}
}