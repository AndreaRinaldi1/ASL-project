import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.HashMap;
import java.util.Map;


public class ServerHandler {
	private Socket socket;
	private PrintWriter output;
	private BufferedReader input;
	private Map<WorkerThread, String> replies;
	
	public ServerHandler(Socket socket) {
		this.socket = socket;
		try {
			this.output = new PrintWriter(socket.getOutputStream(), true);
			this.input = new BufferedReader(new InputStreamReader(socket.getInputStream()));
			replies = new HashMap<>();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	
	
	public Socket getSocket() {
		return socket;
	}

	//qui prima era senza il thread e tutto sequenziale: mandavo richiesta, aspettavo risposta e la rimandavo come return a wt
	public void send(WorkerThread wt, String message){
			output.println(message);
			output.flush();
	}
	
			
	public String receive() {
		
		String serverReply = null;
		
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
	 /*
	  * replies.put(wt, serverReply);	
	  * 
		String risposta = replies.get(wt);
		while(risposta == null) {
			 risposta = replies.get(wt);
		}
		replies.put(wt, null);
		return risposta;
	  */
	
		/*wt.receive(serverReply);
	}
	
}
		};
		th.start();	
	}*/
