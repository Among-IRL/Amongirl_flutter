import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../task_page.dart';

class Socle extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> currentPlayer;

  Socle(this.task, this.currentPlayer);

  @override
  State<StatefulWidget> createState() => SocleState();
}

class SocleState extends State<Socle> {
  SocketIoClient socketIoClient = SocketIoClient();

  late Timer _timer;
  int _start = 10;

  Map<String, dynamic> game = {};

  String message = "";

  @override
  void initState() {
    startTask();
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Socle"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text("Veuillez mettre l'objet dans le socle adéquat"),
              Text("Temps restant : $_start"),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  void startTask() {

    socketIoClient.socket.on('taskCompletedSocle', (data) {
     if(mounted){
       setState(() {
         message = "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
         game = data;
       });
     }
    });


    socketIoClient.socket.on('taskNotComplete', (data){
      if(mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TaskPage(data['game']),
          ),
        );
      }
    });

    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": widget.currentPlayer},
    );
    startTimer();
  }


  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() {
            print("timer key code done");

            socketIoClient.socket.emit("timerTaskDone", {
              "macPlayer": widget.currentPlayer["mac"],
              "macTask": widget.task["mac"],
              "accomplished": true,
            });

            if (game.isNotEmpty) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => TaskPage(game),
                ),
              );
            }
            timer.cancel();
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }
}
