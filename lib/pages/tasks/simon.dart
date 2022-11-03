import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/pages/task_page.dart';
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
  int _start = 30;

  Map<String, dynamic> game = {};

  String message = "";

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
            Text(message),
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

    socketIoClient.socket.on('taskCompletedSimon', (data) {
      if (mounted) {
        setState(() {
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data;
        });
      }
    });

    socketIoClient.socket.on('taskNotComplete', (data) {
      if (mounted) {
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
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          print("timer simon done");

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
        } else {
          if (mounted) {
            setState(() {
              _start--;
            });
          }
        }
      },
    );
  }
}
