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

  Map<String, dynamic> currentPlayer = {};

  String scoreSimon = '';

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

  void startTask() {
    startTimer();
    socketIoClient.socket.on("scoreSimon", (data) {
      scoreSimon = data;
    });

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

    socketIoClient.socket.on('taskCompletedSimon', (data) {
      if (mounted) {
        setState(() {
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data['game'];
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
      socketIoClient.socket.emit(
          'stopTask', {'task': widget.task, 'player': widget.currentPlayer});

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
            builder: (BuildContext context) => TaskPage(
              data['game'],
              currentPlayer,
              blur,
            ),
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
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          print("timer simon done");

          socketIoClient.socket.emit("timerTaskDone", {
            "macPlayer": currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) =>
                    TaskPage(game, currentPlayer, blur),
              ),
            );
          }

          socketIoClient.socket
              .emit('stopTask', {'task': widget.task, 'player': currentPlayer});

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
