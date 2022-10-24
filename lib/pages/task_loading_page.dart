import 'dart:async';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/material.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class TaskLoadingPage extends StatefulWidget {

  // final Map<String, dynamic> game;
  //
  //
  // TaskLoadingPage(this.game);

  static const routeName = 'taskLoadingPage';

  @override
  State<StatefulWidget> createState() => TaskLoadingPageState();
}

class TaskLoadingPageState extends State<TaskLoadingPage> {
  late IO.Socket socket;

  String left = "10";
  bool isTimerFinished = true;

  @override
  void initState() {
    //onSocket();
    super.initState();
  }

  @override
  void dispose() {
    print("dispose");
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("Temps avant de pouvoir confirmer la tâche"),
                  Text(
                    "$left secondes",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isTimerFinished ? () => {} :  null,
                child: const Text('Vailder'),
              ),
            ],
          ),
        ));
  }

  void onSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());
    //
    // socket = IO.io("http://10.57.29.188:3000",
    //     IO.OptionBuilder().setTransports(['websocket']).build());

    // socket.connect();

    // socket.on('meeting', (data) {
    //   print("toto");
    //   print("data in meeting $data");
    //
    //   setStateIfMounted(() {
    //     left = data['countDown'].toString();
    //     print("LEFT = $left");
    //   });
    //   if(data['countDown'] == 0){
    //     socket.clearListeners();
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(
    //         builder: (BuildContext context) => TaskPage(widget.game),
    //       ),
    //     );
    //   }
    // });
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }
}
