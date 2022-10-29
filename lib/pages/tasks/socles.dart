import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Socle extends StatefulWidget {
  final Map<String, dynamic> task;

  Socle(this.task);

  @override
  State<StatefulWidget> createState() => SocleState();
}

class SocleState extends State<Socle> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic> currentPlayer = {};
  SocketIoClient socketIoClient = SocketIoClient();

  late Timer _timer;
  int _start = 10;

  @override
  void initState() {
    whoIam();
    // TODO: START TIMER
    // TODO EMIT START TASK
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
              Text("Veuillez mettre le socle ou il faut"),
            ],
          ),
        ),
      ),
    );
  }

  void startTask() {
    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": currentPlayer},
    );
    startTimer();
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    print("before get player");
    setState(() {
      currentPlayer = json.decode(prefs.getString("currentPlayer")!);
      print("current player = $currentPlayer");
    });
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        print("LEFT TIMER === $_start ");
        if (_start == 0) {
          setState(() {
            print("timer key code done");

            socketIoClient.socket.emit("timerTaskDone", {
              "macPlayer": currentPlayer["mac"],
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
