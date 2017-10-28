import java.io.IOException;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.Scanner;

public class Client {
	private String ip;
	private int port;
	
	public Client(String ip, int port) {
		super();
		this.ip = ip;
		this.port = port;
	}
	
	public static void main(String[] args) {
		Client client = new Client("127.0.0.1", 1337);
		System.out.println("Connection estabilished - client");
		try{
			client.startClient();
		}
		catch(IOException e){
			System.err.println(e.getMessage());			
		}
	}
	
	
	public void startClient() throws IOException{
		Socket socket = new Socket(ip, port);
		Scanner socketIn = new Scanner(socket.getInputStream());
		PrintWriter socketOut = new PrintWriter(socket.getOutputStream());
		Scanner stdin = new Scanner(System.in);
		String message = null;
		do {
			System.out.println("Enter your message: ");
			message = stdin.nextLine();
			socketOut.println(message);
			socketOut.flush();
		} while (!("end".equals(message)));

		while(socketIn.hasNextLine()){
			System.out.println("The middleware reply: ");
			System.out.println(socketIn.nextLine());		
			
		}

	}
}