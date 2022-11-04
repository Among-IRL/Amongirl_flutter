import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../end_game_page.dart';
import '../task_page.dart';
import '../vote_page.dart';

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
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Map<String, dynamic> game = {};

  String message = "";

  bool blur = false;

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
              BackdropFilter(
                filter: blur
                    ? ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)
                    : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
                child: Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startTask() {
    socketIoClient.socket.on('taskCompletedSocle', (data) {
      if (mounted) {
        setState(() {
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data['game'];
        });
      }
    });

    socketIoClient.socket.on('sabotage', (data) {
      if(mounted) {
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

    socketIoClient.socket.on('win', (data) {
      print('WIN');
      if (mounted) {
        print("mounted = $mounted");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EndGamePage(data)),
        );
      }
    });

    socketIoClient.socket.on('report', (data) {
      if(mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(data),
          ),
        );
      }
    });

    socketIoClient.socket.on('buzzer', (data) {
      if(mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(data),
          ),
        );
      }
    });

    socketIoClient.socket.on('deathPlayer', (data){
      socketIoClient.socket.emit('stopTask', {
        'task': widget.task,
        'player': widget.currentPlayer
      });

      updateCurrentPlayer(data['isAlive'], data['isDeadReport']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TaskPage(data['game'], blur),
          ),
        );
      }
    });


    socketIoClient.socket.on('taskNotComplete', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TaskPage(data['game'], blur),
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
                builder: (BuildContext context) => TaskPage(game, blur),
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
