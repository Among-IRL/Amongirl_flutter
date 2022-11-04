import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../end_game_page.dart';
import '../vote_page.dart';

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

  Map<String, dynamic> currentPlayer = {};

  String message = "";

  String playerWhoCompleteTask = "";

  // final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Timer _timer;
  int _start = 10;

  bool blur = false;

  @override
  void initState() {
    currentPlayer = widget.currentPlayer;
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
            BackdropFilter(
              filter: blur
                  ? ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)
                  : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startTask() async {
    startTimer();

    socketIoClient.socket.on('win', (data) {
      print('WIN');
      if (mounted) {
        print("mounted = $mounted");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EndGamePage(data)),
        );
      }
    });

    socketIoClient.socket.on('sabotage', (data) {
      if (mounted) {
        setState(() {
          blur = data;
        });
      }
    });

    socketIoClient.socket.on('taskCompletedDesabotage', (data) {
      if (mounted) {
        setState(() {
          blur = false;
        });
      }
    });

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

    socketIoClient.socket.on('report', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(
              data,
              currentPlayer,
            ),
          ),
        );
      }
    });

    socketIoClient.socket.on('buzzer', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(
              data,
              currentPlayer,
            ),
          ),
        );
      }
    });

    socketIoClient.socket.on('deathPlayer', (data) {
      socketIoClient.socket
          .emit('stopTask', {'task': widget.task, 'player': currentPlayer});

      updateCurrentPlayer(data['isAlive'], data['isDeadReport']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                TaskPage(data['game'], currentPlayer, blur),
          ),
        );
      }
    });

    socketIoClient.socket.on('taskNotComplete', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                TaskPage(data['game'], currentPlayer, blur),
          ),
        );
      }
    });

    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": currentPlayer},
    );
  }

  updateCurrentPlayer(isAlive, isDeadReport) async {
    // final SharedPreferences prefs = await _prefs;
    // final current = prefs.getString("currentPlayer");
    // if (current != null) {
    //   final currentDecoded = json.decode(current);
    if (mounted) {
      setState(() {
        currentPlayer['isAlive'] = isAlive;
        currentPlayer['isDeadReport'] = isDeadReport;
      });
    }

    // prefs.setString("currentPlayer", json.encode(currentDecoded));
    //
    // }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          print("timer swipe card done");

          socketIoClient.socket.emit("timerTaskDone", {
            "macPlayer": currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty &&
              playerWhoCompleteTask == currentPlayer['mac']) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => TaskPage(game, currentPlayer, blur),
              ),
            );
          }

          socketIoClient.socket.emit('stopTask',
              {'task': widget.task, 'player': currentPlayer});

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
