import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.List;
import java.util.Queue;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class MyMiddleware implements Runnable{

	static String myIp;
	static int myPort;
	static List<String> mcAddresses;
	static int numThreadsPTP;
	static boolean readSharded;
	static volatile boolean keepRunning = true;
	private ServerSocketChannel inputSocket;
	private SocketChannel clientChannel;
	private ExecutorService workerThreads;
	private static ArrayList<ServerHandler> serverHandlers = new ArrayList<>();
	//private Map<String, Integer> servers = new HashMap<>();
    private Queue<Job> queue = new  ConcurrentLinkedQueue<>();
    private static int serverCount = 0;
	String[][] parts;
	ArrayList<Socket> sockets = new ArrayList<>();
	public static int numOfGets = 0;
	public static int numOfSets = 0;
	public static int numOfMultiGets = 0;
	int totalServiceTime = 0;
	int numOfRequests = 0;
	public static final Logger QUEUELENGTH = LogManager.getLogger("QueueLength");
	public static final Logger REQUESTSTYPE = LogManager.getLogger("RequestsType");
	//public static final Logger FINALINFO = LogManager.getLogger("FinalInfo");
	
	public MyMiddleware(String myIp, int myPort,List<String> mcAddresses,int numThreadsPTP,boolean readSharded){
		MyMiddleware.myIp = myIp;
		MyMiddleware.myPort = myPort;
		MyMiddleware.mcAddresses = mcAddresses;
		MyMiddleware.numThreadsPTP = numThreadsPTP;
		MyMiddleware.readSharded = readSharded;		
	}
	
	@Override
	public void run() {
		Runtime.getRuntime().addShutdownHook(new Thread() {
		    public void run() {
				System.out.println("Qui ci vanno le statistiche da fare al termine");
				keepRunning = false;
				workerThreads.shutdown();
				REQUESTSTYPE.info("GET: " + numOfGets);
				REQUESTSTYPE.info("SET: " + numOfSets);
				REQUESTSTYPE.info("MULTIGET: " + numOfMultiGets);
				
				/*FileInputStream fstream = null;
				try {
					fstream = new FileInputStream("/home/andrea/eclipse-workspace/ASL_Working/resources/serviceTime.log");
				} catch (FileNotFoundException e) {
					e.printStackTrace();
				}
				BufferedReader br = new BufferedReader(new InputStreamReader(fstream));
				String strLine;
				
				
				try {
					while ((strLine = br.readLine()) != null)   {
						totalServiceTime += Integer.parseInt(strLine);
						numOfRequests++;
						
					}
				} catch (NumberFormatException | IOException e) {
					e.printStackTrace();
				}
				System.out.println(totalServiceTime);
				System.out.println(numOfRequests);
				FINALINFO.info("Total time spent in service: " + totalServiceTime);
				FINALINFO.info("\nNumber of requests: " + numOfRequests);
				FINALINFO.info("\nAVG time spent in service per request: " + totalServiceTime / numOfRequests);
				System.out.println("BYE BYE");
				System.out.println("END");  */

				
		    }
	    });
						
		
		/*
		 * Here I initialize the middleware port, backlog and IP address to bind to (in input)
		 */
		try {
			inputSocket = ServerSocketChannel.open();
			inputSocket.bind(new InetSocketAddress(myIp, myPort));
		} catch(IOException e){
			System.err.println("Cannot start the middleware input socket");
		}
		
		System.out.println("MyMidldleware - I instanciated inputSocket. Address: " + myIp + " Port: " + myPort);
		
		/*
		 * Here I initialize the servers and put them in a List
		 */
		getServers();
			
		for(int i = 0; i < mcAddresses.size(); i++){
			try {
				int port = Integer.parseInt(parts[i][1]);
				Socket socket = new Socket(parts[i][0], port);
				sockets.add(socket);
				ServerHandler sh = new ServerHandler(socket);
				serverHandlers.add(sh);
				System.out.println("MyMiddleware - ServerHandler done "  + parts[i][0] + " " + port);

			} catch (IOException e){
				e.printStackTrace();
			}
			
		}
		
		
		/*
		 * Here I initialize the worker threads and put them in a Fixed Thread Pool
		 */
        workerThreads = Executors.newFixedThreadPool(128);
        for(int i = 0; i < numThreadsPTP; i++){
        	WorkerThread wt = new WorkerThread(i, parts, queue);
        	workerThreads.submit(wt);
        }
		
        System.out.println("MyMiddleware - WorkerThread done");
		
        /*
		 * This is the initialization of the middleware portion that interfaces with the clients
		 */
		Selector selector = null;
        try {
			selector = Selector.open();
		} catch (IOException e1) {
			e1.printStackTrace();
		}

        ClientHandler instance = ClientHandler.getInstance();
        instance.setQueue(queue);
        instance.setSelector(selector);
        
        new Thread(instance).start();
        try {
        	clientChannel = inputSocket.accept();
    		if(clientChannel != null){
    			clientChannel.configureBlocking(false);

    			clientChannel.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(256));
    			System.out.println("connection estabilished");
    			Timer timer = new Timer();
    			timer.scheduleAtFixedRate(new TimerTask() {
    				public void run() {
    					QUEUELENGTH.info(queue.size());
    				}
    			}, 0, 5);
    		}
        }catch(IOException e) {
        	
        }
        
		
        while(keepRunning){
        	try {
        		
    			clientChannel = inputSocket.accept();
    			if(clientChannel != null){
    				clientChannel.configureBlocking(false);

    				clientChannel.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(256));
    				System.out.println("connection estabilished");
    				
    				for(SelectionKey k : selector.keys()) {
    					System.out.println(k);
    				}
      		    }
    			
        	}
        	catch(IOException e){
        		System.err.println("Cannot accept clients connections");
        	}
        }       
	}
	
	/**
	 * This method splits the mcAddress IP in the servers IP Adresses and their port
	 * @return the Map with the IP Adresses and Ports of the servers
	 */
	private void getServers(){
		parts = new String[mcAddresses.size()][2];
		for(int numOfServers = 0; numOfServers < mcAddresses.size(); numOfServers++){
			parts[numOfServers] = mcAddresses.get(numOfServers).split(":");
			//servers.put(parts[0], Integer.parseInt(parts[1]));
		}	
		
	}
	
	private void finalinfo() {
		
	}
	
	public synchronized static int loadBalance() {
		serverCount++;
		serverCount = (serverCount) % (mcAddresses.size());
		return serverCount;
	}

}
