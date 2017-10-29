import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Queue;
import java.util.Scanner;
import java.util.Set;


public class ClientHandler implements Runnable {
	Scanner input = null;
	Queue<Job> queue;
	Selector selector;
	int count = 0;
	long arrivalTime;
	private static ClientHandler instance;


	private ClientHandler() {}
	
	public static ClientHandler getInstance() {
		if(instance == null) {
			instance = new ClientHandler();
		}
		return instance;
	}
	
	public void setQueue(Queue<Job> queue) {
		this.queue = queue;
	}

	public void setSelector(Selector selector) {
		this.selector = selector;
	}

	@Override
	public void run() {
		while(true) {

			try {
				if(selector.selectNow() == 0) continue;
			} catch (IOException e1) {
				e1.printStackTrace();
			}

			
			Set<SelectionKey> selectedKeys = selector.selectedKeys();
			Iterator<SelectionKey> keyIterator = selectedKeys.iterator();
			while(keyIterator.hasNext()) {
				SelectionKey key = keyIterator.next();
				if(key.isReadable()) {
					try {
						arrivalTime = System.nanoTime();
						sendRequest(key);
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
				keyIterator.remove();
				
					//Altrimenti, con synchronized(buf) nel metodo sendRequest:
					/*Thread th = new Thread() {
						public void run() {
							try {
								sendRequest(key);
							} catch (IOException e) {
								// TODO Auto-generated catch block
								e.printStackTrace();
							}
						}
					};
					th.start();
				}
				keyIterator.remove();*/
			}
		}
	}
						
	public void sendRequest(SelectionKey key) throws IOException{
		SocketChannel socketChannel = (SocketChannel) key.channel(); 
		String message = "";
		ByteBuffer buf = (ByteBuffer) key.attachment();
		
		socketChannel.read(buf);
		buf.flip();
		while (buf.hasRemaining()) {
				message += Charset.defaultCharset().decode(buf);
		}
		//String message = new String(buf.array()).trim();
		buf.clear();
	
		if(message.length() > 0) {
			message = message.substring(0, message.length()-1);
			//message += "\r";
			Job job = new Job(message, key, arrivalTime, System.nanoTime());
			queue.add(job);
		}
		else {
			key.channel().close();
			key.cancel();
		}
			/*try {
				System.out.println("1 " + buf.position() + " " + buf.limit());
				socketChannel.read(buf); //read into buffer.
				System.out.println("2 " + buf.position() + " " + buf.limit());
			} catch (IOException e) {} 
	
			if(buf.position() != 0) {
				buf.flip();  //make buffer ready for read
				inputLine = "";
				System.out.println("4 " + buf.position() + " " + buf.limit());

				while(buf.hasRemaining()){
					inputLine += (char) buf.get(); // read 1 byte at a time
				  
				}

				
				System.out.println("5 " + buf.position() + " " + buf.limit());
	
				inputLine = inputLine.substring(0, inputLine.length()-1);
	
				System.out.println("ClientHandler - received the request #" + count + " " + inputLine);
				count++;
				
				Job job = new Job(inputLine, key);
				queue.add(job);
				
				buf.clear(); //make buffer ready for writing
				System.out.println("6 " + buf.position() + " " + buf.limit());
			
			}
			else {
				selector.keys().remove(key);
				if(selector.selectedKeys().isEmpty()) {
					try {
						selector.close();
					} catch (IOException e) {
						e.printStackTrace();
					}
				}
			}
			*/
		
	}
	
	
	public void send(SelectionKey key, String message){
		SocketChannel socketChannel = (SocketChannel) key.channel(); 

		// write some data into the channel
		//message += "\r\n";
		CharBuffer buffer = CharBuffer.wrap(message);
		while (buffer.hasRemaining()) {
			try {
				socketChannel.write(Charset.defaultCharset().encode(buffer));
			} catch (IOException e) {
				e.printStackTrace();
			}
		
		}

		
		/*System.out.println("ClientHandler - I received the response message");
		System.out.println(message);
		message += "\r\n";
		System.out.println("8 " + buf.position() + " " + buf.limit());
		
		buf.clear();
		System.out.println("9 " + buf.position() + " " + buf.limit());
		buf.wrap(message.getBytes());
		//buf.put(message.getBytes());
		System.out.println("10 " + buf.position() + " " + buf.limit());

		buf.flip();
		System.out.println("11 " + buf.position() + " " + buf.limit());
		synchronized(buf) {
			try {
				while(buf.hasRemaining()) {
					socketChannel.write(buf);
				}
			} catch (IOException e) {}
			System.out.println("12 " + buf.position() + " " + buf.limit());
			buf.clear();
			System.out.println("13 " + buf.position() + " " + buf.limit());
		}
		System.out.println("ClientHandler - The response message from memcached has been sent back to memtier");*/
	}
}
