import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Simon extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> currentPlayer;

  Simon(this.task, this.currentPlayer);

  @override
  State<StatefulWidget> createState() => SimonState();
}

class SimonState extends State<Simon> {
  SocketIoClient socketIoClient = SocketIoClient();

  late Timer _timer;
  int _start = 10;

  String scoreSimon = '';

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
        title: Text("Simon"),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Temps restant : $_start"),
            Text("Veuillez jouer au simon"),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Votre score"),
                  Text(
                    scoreSimon,
                    style: TextStyle(fontSize: 50),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startTask() {
    startTimer();
    socketIoClient.socket.on("scoreSimon", (data) {
      scoreSimon = data;
    });

    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": widget.currentPlayer},
    );
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        print("LEFT TIMER === $_start ");
        if (_start == 0) {
          setState(() {
            print("timer simon done");

            socketIoClient.socket.emit("timerTaskDone", {
              "macPlayer": widget.currentPlayer["mac"],
              "macTask": widget.task["mac"],
              "accomplished": true,
            });
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
