package ch.ethz.asltest;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.channels.ClosedChannelException;
import java.nio.channels.ClosedSelectorException;
import java.nio.channels.SelectionKey;
import java.nio.channels.Selector;
import java.nio.channels.SocketChannel;
import java.nio.charset.Charset;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Scanner;
import java.util.Set;
import java.util.concurrent.LinkedBlockingQueue;


/**
 * This class implements the Net Thread, that is where the clients send their requests to. This singleton instance
 * makes use of non-blocking I/O for the incoming requests from the clients, so that, when one client is ready to 
 * write, the message is read from the channel into the buffer and a new Job is created. Lastly, the net thread
 * puts this new job into the queue, and goes on handling the next incoming request from the clients.
 * @author andrea
 *
 */
public class ClientHandler implements Runnable {
	Scanner input = null;
	LinkedBlockingQueue<Job> queue;
	Selector selector;
	int count = 0;
	long arrivalTime;
	long previousTime = 0;
	private static ClientHandler instance;
	SocketChannel socketChannel;
	ByteBuffer buf;
	String message;
	public ArrayList<Long> interArrivalTimes = new ArrayList<>();

	private ClientHandler() {}
	
	public static ClientHandler getInstance() {
		if(instance == null) {
			instance = new ClientHandler();
		}
		return instance;
	}
	
	public void setQueue(LinkedBlockingQueue<Job> queue) {
		this.queue = queue;
	}

	public void setSelector(Selector selector) {
		this.selector = selector;
	}

	@Override
	public void run() {
		
		while(selector.isOpen()) {

			try {
				if(selector.selectNow() == 0) continue;
			} catch (IOException | ClosedSelectorException e1) {
				System.out.println("The selector was closed");
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
			}
		}
	}
	
	/**
	 * In this function the net thread reads the incoming request from the buffer, builds a new Job with
	 * that message body in it and the other time variables, and puts it in the queue.
	 * @param key the client that submitted the request
	 */
	public void sendRequest(SelectionKey key) throws IOException{
		socketChannel = (SocketChannel) key.channel(); 
		message = "";
		buf = (ByteBuffer) key.attachment();
		
		while(socketChannel.isOpen()) {
			socketChannel.read(buf);

			buf.flip();
			while (buf.hasRemaining()) {
					message += Charset.defaultCharset().decode(buf);
			}
			buf.clear();
		
			if(message.length() > 0) {
				if(message.endsWith("\r\n")) {
					message = message.substring(0, message.length()-1);
					Job job = new Job(message, key, arrivalTime, System.nanoTime());
					queue.add(job);
					interArrivalTimes.add(arrivalTime - previousTime);
					previousTime = arrivalTime;
					return;
				}
			}
			else {
				key.channel().close();
				key.cancel();
			}
		}
		
	}
	
}
