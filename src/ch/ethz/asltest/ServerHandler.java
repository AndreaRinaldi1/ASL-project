package ch.ethz.asltest;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;



public class ServerHandler {
	private Socket socket;
	private PrintWriter output;
	private BufferedReader input;
	String serverReply = null;
	int load = 0;
	
	public ServerHandler(Socket socket) {
		this.socket = socket;
		try {
			this.output = new PrintWriter(socket.getOutputStream(), true);
			this.input = new BufferedReader(new InputStreamReader(socket.getInputStream()));
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	
	public Socket getSocket() {
		return socket;
	}

	public void send(WorkerThread wt, String message){
		load += 1;
		output.println(message);
		output.flush();
	}
	
			
	public String receive() {		
		try {
			serverReply = input.readLine();
			while(!(serverReply.endsWith("END")) && !(serverReply.endsWith("STORED"))) {
				serverReply += "\r\n" +  input.readLine();
			}
		} catch (IOException e) {
			e.printStackTrace();
		}
		
		return serverReply;
	}
}