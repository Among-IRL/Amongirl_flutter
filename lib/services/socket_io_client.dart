import "package:socket_io_client/socket_io_client.dart" as IO;

import '../config/config.dart';

class SocketIoClient {
  IO.Socket socket = IO.io("http://$ip_address:3000",
      IO.OptionBuilder().setTransports(['websocket']).build());
}