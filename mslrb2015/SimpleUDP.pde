import java.net.InetSocketAddress;
import java.nio.ByteBuffer;
import java.nio.channels.DatagramChannel;
import java.nio.charset.StandardCharsets;

public class SimpleUDP {
    private DatagramChannel channel;
    private InetSocketAddress address;
    private int port;

    // Constructor for sender
    public SimpleUDP(String address, int port) throws Exception {
        this.address = new InetSocketAddress(address, port);
        this.channel = DatagramChannel.open();
        this.channel.configureBlocking(false); // Set the channel to non-blocking mode
    }

    // Constructor for receiver
    public SimpleUDP(int port) throws Exception {
        this.port = port;
        this.channel = DatagramChannel.open();
        this.channel.bind(new InetSocketAddress(port));
        this.channel.configureBlocking(false); // Set the channel to non-blocking mode
    }

    public SimpleUDP()  {
        // Do nothing
        System.out.println("SimpleUDP object created");
    }

    public void init(int port) throws Exception {
        this.port = port;
        this.channel = DatagramChannel.open();
        this.channel.bind(new InetSocketAddress(port));
        this.channel.configureBlocking(false); // Set the channel to non-blocking mode
    }

    // Method to send a message
    public void sendMessage(String message) throws Exception {
        if(channel == null || !channel.isOpen()){
            return;
        }

        ByteBuffer buffer = ByteBuffer.wrap(message.getBytes());
        channel.send(buffer, address);
    }

    // Method to receive a message
    public String receiveMessage() throws Exception {
        if(channel == null || !channel.isOpen()){
            return null;
        }

        ByteBuffer buffer = ByteBuffer.allocate(1024);
        InetSocketAddress senderAddress = (InetSocketAddress) channel.receive(buffer);
        if (senderAddress != null) {
            buffer.flip();
            return StandardCharsets.UTF_8.decode(buffer).toString();
        }
    return null;
    }

    // Method to receive a message in bytes
    public byte[] receiveMessageBytes() throws Exception {
        if(channel == null || !channel.isOpen()){
            return null;
        }


        ByteBuffer buffer = ByteBuffer.allocate(1024);
        InetSocketAddress senderAddress = (InetSocketAddress) channel.receive(buffer);
        if (senderAddress != null) {
            buffer.flip();
            byte[] receivedData = new byte[buffer.remaining()];
            buffer.get(receivedData);
            return receivedData;
        }
        return null;
    }


    // Close the channel
    public void close() throws Exception {
        if (channel != null && channel.isOpen()) {
            channel.close();
        }
    }
}
