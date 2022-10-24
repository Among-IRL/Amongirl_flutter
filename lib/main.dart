import 'package:amoungirl/config/config.dart';
import 'package:amoungirl/pages/game_config_page.dart';
import 'package:flutter/material.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

void main() {
  runApp(const MyApp());

  // IO.Socket socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
  //     IO.OptionBuilder().setTransports(['websocket']).build());
  IO.Socket socket = IO.io("http://${ip_address}:3000",
      IO.OptionBuilder().setTransports(['websocket']).build());

  socket.connect();

  socket.on('connect', (data) {
    print("socket connect ${socket.connected}");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        GameConfigPage.routeName: (context) => GameConfigPage(),
        // RoleAllocationPage.routeName: (context) => RoleAllocationPage(null),
        // TaskPage.routeName: (context) => TaskPage(),
        // VotePage.routeName: (context) => VotePage(),
        // EndGamePage.routeName: (context) => EndGamePage(),
      },
      home: GameConfigPage(),
    );
  }
}
