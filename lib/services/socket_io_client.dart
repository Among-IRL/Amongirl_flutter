import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

import '../config/config.dart';
import '../pages/end_game_page.dart';

class SocketIoClient {
  IO.Socket socket = IO.io("http://$ip_address:3000",
      IO.OptionBuilder().setTransports(['websocket']).build());
}