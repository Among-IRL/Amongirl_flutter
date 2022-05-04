import 'dart:async';

import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class VotePage extends StatefulWidget {
  static const routeName = 'vote';

  @override
  State<StatefulWidget> createState() => VotePageState();
}

class VotePageState extends State<VotePage> {
  late IO.Socket socket;

  String left = "";

  @override
  void initState() {
    onSocket();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Vote"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("C'est la réu les gars, il est temps de tuer du boug"),
              Text(
                "$left secondes",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ));
  }

  void onSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());
    socket = IO.io("http://192.168.1.18:3000",
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();

    socket.on('connect', (data) {
      // socket.emit('startGame');
      print("socket connect ${socket.connected}");
    });

    socket.on('meeting', (data) {
      setState(() {
        left = data['countDown'].toString();
      });
      if(data['countDown'] == 0){
        Navigator.of(context).pop();
      }
    });
  }
}
