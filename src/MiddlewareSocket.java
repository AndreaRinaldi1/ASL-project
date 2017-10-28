import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketException;
import java.net.SocketImpl;
import java.net.UnknownHostException;
import java.util.logging.Level;
import java.util.logging.Logger;

public class MiddlewareSocket extends Socket{
	

	public MiddlewareSocket(String myIp, int myPort) throws IOException {
		super(myIp, myPort);
	}

}