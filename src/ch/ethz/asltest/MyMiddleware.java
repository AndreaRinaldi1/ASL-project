package ch.ethz.asltest;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.nio.ByteBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.ServerSocketChannel;
import java.nio.channels.SocketChannel;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingQueue;


public class MyMiddleware implements Runnable{

	static String myIp;
	static int myPort;
	static List<String> mcAddresses;
	static int numThreadsPTP;
	static boolean readSharded;
	static volatile boolean keepRunning = true;
	private ServerSocketChannel inputSocket;
	private SocketChannel clientChannel;
	private ExecutorService workerThreadsExe;
	private ArrayList<WorkerThread> workerThreads = new ArrayList<>();
    private LinkedBlockingQueue<Job> queue = new  LinkedBlockingQueue<>();
	String[][] parts;
	float totalMiss = 0;
	Selector selector = null;
	int numOfRequests = 0;
	
	String filePath = null;
	String prefixNS = "/home/arinaldi/results/";

	public static ArrayList<Float> throughput = new ArrayList<>(); 
	public static ArrayList<String> workersThroughput = new ArrayList<>();
	public static ArrayList<String> times = new ArrayList<>();
	public static ArrayList<Long> interArrivalTime = new ArrayList<>();
	public static ArrayList<Long> queueLength = new ArrayList<>();
	public static ArrayList<String> unproperRequests = new ArrayList<>();

	Map<String, Integer> serversLoad = new HashMap<>();
	Map<String, Integer> requestsType = new HashMap<>();

	FileWriter fileWriter = null;
	BufferedWriter bufWriter = null;

	public MyMiddleware(String myIp, int myPort,List<String> mcAddresses,int numThreadsPTP,boolean readSharded){
		MyMiddleware.myIp = myIp;
		MyMiddleware.myPort = myPort;
		MyMiddleware.mcAddresses = mcAddresses;
		MyMiddleware.numThreadsPTP = numThreadsPTP;
		MyMiddleware.readSharded = readSharded;		
	}
	
	@Override
	public void run() {
		System.out.println("MW Running");
			
		times.add("WT\tTYPE\tQUEUE\tWORKER\tPROCESS\tSERVICE\tRESP.\tTIME IN SYSTEM");
		/*
		 * Here I initialize the middleware port, backlog and IP address to bind to (in input)
		 */
		try {
			inputSocket = ServerSocketChannel.open();
			inputSocket.configureBlocking(false);
			inputSocket.bind(new InetSocketAddress(myIp, myPort));
		} catch(IOException e){
			System.err.println("Cannot start the middleware input socket");
		}
		
		//System.out.println("MyMidldleware - I instanciated inputSocket. Address: " + myIp + " Port: " + myPort);
		
		/*
		 * Here I initialize the servers and put them in a List
		 */
		getServers();
			
		for(int i = 0; i < mcAddresses.size(); i++){
			serversLoad.put("/"+parts[i][0], 0);
		}
		
		
		/*
		 * Here I initialize the worker threads and put them in a Fixed Thread Pool
		 */
        workerThreadsExe = Executors.newFixedThreadPool(numThreadsPTP);
        for(int i = 0; i < numThreadsPTP; i++){
        	WorkerThread wt = new WorkerThread(i, parts, queue);
        	workerThreadsExe.submit(wt);
        	workerThreads.add(wt);
        }
        
        
		Timer timer = new Timer();
		timer.scheduleAtFixedRate(new TimerTask() {
			public void run() {
				ClientHandler.getInstance().interArrivalTimes.clear();
				for(WorkerThread wt : workerThreads) {
					wt.myNumOfRequests = 0;
					wt.times.clear();
					wt.resetTime = System.nanoTime();
				}
				WorkerThread.numOfRequests.set(0);
				
				try {
					Thread.sleep(4000); // colleziono dati per tot secondi (finestra)
				} catch (InterruptedException e) {}
				
				throughput.add(WorkerThread.numOfRequests.floatValue() / 4);
				interArrivalTime.addAll(ClientHandler.getInstance().interArrivalTimes);
				for(WorkerThread wt : workerThreads) {
					times.addAll(wt.times);
					unproperRequests.addAll(wt.unproperRequests);
					wt.myThroughput.add((wt.myNumOfRequests * 1000000000 / (System.nanoTime() - wt.resetTime))+"");
				}
			}
		}, 8000 , 6400); //prima di ricollezionare dei dati aspetto tot
				

		
        //System.out.println("MyMiddleware - WorkerThread done");
		
        /*
		 * This is the initialization of the middleware portion that interfaces with the clients
		 */
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

    			clientChannel.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(1080));
    			//System.out.println("connection estabilished");
    		}
        }catch(IOException e) {
        	
        }
        
        Timer timer2 = new Timer();
		timer2.scheduleAtFixedRate(new TimerTask() {
			public void run() {
				  queueLength.add((long)queue.size());
			}
		}, 0, 50);
		
		
		
		Runtime.getRuntime().addShutdownHook(new Thread() {
		    public void run() {
				try {
					requestsType.put("GET", 0);
					requestsType.put("SET", 0);
					requestsType.put("MULTIGET", 0);
										
					for(int i = 0; i < workerThreads.size(); i++) {
						workersThroughput.add("WORKER " + workerThreads.get(i).myNumber);
						workersThroughput.addAll(workerThreads.get(i).myThroughput);
						workersThroughput.add("");
						
						for(ServerHandler s : workerThreads.get(i).servers) {
							serversLoad.put(s.getSocket().getInetAddress().toString(), serversLoad.get(s.getSocket().getInetAddress().toString())+s.load);
						}
						requestsType.put("GET", requestsType.get("GET")+workerThreads.get(i).numOfGets);
						requestsType.put("SET", requestsType.get("SET")+workerThreads.get(i).numOfSets);
						requestsType.put("MULTIGET", requestsType.get("MULTIGET")+workerThreads.get(i).numOfMultiGets);

						totalMiss += workerThreads.get(i).miss;
						
						
					}
					for(int i = 0; i < workerThreads.size(); i++) {
						queue.add(new Job("EXIT", null, 0, 0));
					}
					write2(interArrivalTime, "interArrivalTime.log");
					write2(queueLength, "QueueLength.log");

					write(times, "times.log");
					write(workersThroughput, "WorkersThroughput.log");
					write(unproperRequests, "errorMessages.log");
					
					filePath = prefixNS+"Throughput.log";
					fileWriter = new FileWriter(filePath);
					bufWriter = new BufferedWriter(fileWriter);
					for(Float f : throughput) {
						bufWriter.write(f+"\n");
					}
					bufWriter.flush();

					filePath = prefixNS+"CacheMisses.log";
					fileWriter = new FileWriter(filePath);
					bufWriter = new BufferedWriter(fileWriter);
					bufWriter.write("Total number of misses: " + totalMiss +"\n");
					bufWriter.write("Miss ratio: " + (totalMiss/(requestsType.get("GET")+ requestsType.get("MULTIGET"))));
					bufWriter.flush();
					
					filePath = prefixNS+"requestsType.log";
					fileWriter = new FileWriter(filePath);
					bufWriter = new BufferedWriter(fileWriter);
					for(String x : requestsType.keySet()) {
						bufWriter.write(x +" "+requestsType.get(x)+"\n");
					}
					bufWriter.flush();

					filePath = prefixNS+"serversLoad.log";
					fileWriter = new FileWriter(filePath);
					bufWriter = new BufferedWriter(fileWriter);
					for(String i : serversLoad.keySet()) {
						bufWriter.write(i +" "+serversLoad.get(i)+"\n");
					}
					bufWriter.flush();
					keepRunning = false;
					
					Iterator<SelectionKey> keyIterator = selector.selectedKeys().iterator();
					while(keyIterator.hasNext()) {
						keyIterator.next().channel().close();
						keyIterator.next().cancel();
					}
					selector.close();
					inputSocket.close();
					
					//editGCMonitoring();
					
				} catch (IOException e1) {
					e1.printStackTrace();
				}
							
		    }
	    });
		
		
        while(keepRunning){
        	try {
    			clientChannel = inputSocket.accept();
    			if(clientChannel != null){
    				clientChannel.configureBlocking(false);

    				clientChannel.register(selector, SelectionKey.OP_READ, ByteBuffer.allocate(12000));
    				//System.out.println("connection estabilished");
      		    }    			
        	}
        	catch(IOException e){
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
	
	private void write(ArrayList<String> myList, String fileName) throws IOException {
		filePath = prefixNS+fileName;
		fileWriter = new FileWriter(filePath);
		bufWriter = new BufferedWriter(fileWriter);
		for(int i = 0; i < myList.size(); i++) {
			bufWriter.write(myList.get(i)+"\n");
		}
		bufWriter.flush();
	}
	
	private void write2(ArrayList<Long> myList, String fileName) throws IOException {
		filePath = prefixNS+fileName;
		fileWriter = new FileWriter(filePath);
		bufWriter = new BufferedWriter(fileWriter);
		for(int i = 0; i < myList.size(); i++) {
			bufWriter.write(myList.get(i)+"\n");
		}
		bufWriter.flush();
	}
	
	
	
	
	/*private void editGCMonitoring() {
		final String FILEINPUT = "/home/andrea/eclipse-workspace/ASL_Working/resources/garbage.log";
		File fileInput = new File(FILEINPUT);
		BufferedReader reader = null;
		String text = null;
		ArrayList<Long> times = new ArrayList<>();

		try {
			fileWriter = new FileWriter(prefixNS+"garbageTimes.log");
			bufWriter = new BufferedWriter(fileWriter);
		} catch (IOException e1) {
			e1.printStackTrace();
		}

	    try {
			reader = new BufferedReader(new FileReader(fileInput));
			for(int i = 0; i < 3; i++) {
				 reader.readLine();
			}
			
		    while((text = reader.readLine()) != null) {
		    	String timeCreated = text.substring(0,28);
		    	DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ");
		        
	            Date timeCreatedDate = null;
				try {
					timeCreatedDate = dateFormat.parse(timeCreated);
					Long d = timeCreatedDate.getTime();
					times.add(d);
				} catch (ParseException e) {
					e.printStackTrace();
				}				
		    }
		    for(Long x : times) {
				bufWriter.write(x.toString()+"\n");
			}
			bufWriter.flush();

		    
		    
	    } catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
		    e.printStackTrace();
		} finally {
		    try {
		        if (reader != null) {
		            reader.close();
		        }
		    } catch (IOException e) {
		    }
		}
	}*/

}
