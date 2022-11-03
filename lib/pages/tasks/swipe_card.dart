import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SwipeCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> currentPlayer;

  SwipeCard(this.task, this.currentPlayer);

  @override
  State<StatefulWidget> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard> {
  SocketIoClient socketIoClient = SocketIoClient();

  Map<String, dynamic> game = {};

  String message = "";

  String playerWhoCompleteTask = "";

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Timer _timer;
  int _start = 10;

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
        title: Text("Carte"),
      ),
      body: Center(
        child: Column(
          children: [
            Text("Veuillez confirmer votre identité"),
            Text("Temps restant : $_start"),
            Text(message),
          ],
        ),
      ),
    );
  }

  void startTask() {
    startTimer();

    socketIoClient.socket.on("taskCompletedTaskCardSwip", (data) {
      print("DATA tasks completed task card swipe ${data["game"]}");

      if (mounted) {
        setState(() {
          playerWhoCompleteTask = data['macPlayer'];
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data["game"];
        });
      }
    });

    socketIoClient.socket.on('deathPlayer', (data){
      if(data['mac'] == widget.currentPlayer['mac']) {
        socketIoClient.socket.emit('stopTask', {
          'task': widget.task,
          'player': widget.currentPlayer
        });

        updateCurrentPlayer(data['isAlive'], data['isDeadReport']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TaskPage(data['game']),
          ),
        );
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

  updateCurrentPlayer(isAlive, isDeadReport) async {
    final SharedPreferences prefs = await _prefs;
    final current = prefs.getString("currentPlayer");
    if (current != null) {
      final currentDecoded = json.decode(current);
      currentDecoded['isAlive'] = isAlive;
      currentDecoded['isDeadReport'] = isDeadReport;
      prefs.setString("currentPlayer", json.encode(currentDecoded));

    }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          print("timer swipe card done");

          socketIoClient.socket.emit("timerTaskDone", {
            "macPlayer": widget.currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty && playerWhoCompleteTask == widget.currentPlayer['mac']) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => TaskPage(game),
              ),
            );
          }

          socketIoClient.socket.emit('stopTask', {
            'task': widget.task,
            'player': widget.currentPlayer
          });

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
