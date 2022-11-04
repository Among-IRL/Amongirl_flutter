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

class KeyCode extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> currentPlayer;

  KeyCode(this.task, this.currentPlayer);

  @override
  State<StatefulWidget> createState() => KeyCodeState();
}

class KeyCodeState extends State<KeyCode> {
  SocketIoClient socketIoClient = SocketIoClient();

  TextEditingController firstInput = TextEditingController();
  TextEditingController secondInput = TextEditingController();
  TextEditingController thirdInput = TextEditingController();
  TextEditingController fourthInput = TextEditingController();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  var taskKeyPressed = [];

  Map<String, dynamic> game = {};

  var taskCodeToFound = [];

  Map<String, dynamic> currentPlayer = {};

  // var displayCode = ["*", "*", "*", "*"];

  List<List<dynamic>> codeRemember = [[]];

  late Timer _timer;
  int _start = 60;

  String message = "";

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
        title: const Text("Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              const Text("Veuillez entrer le code qui vous à été donné"),
              Text("Temps restant : $_start"),
              Text(message),
              Text(prettyCode(taskCodeToFound)),
              // displayCode == taskCodeToFound
              //     ? const Text(
              //         "Vous avez trouver le code, veuillez le taper entierement pour valider la tâche")
              //     : Container(),
              Text(prettyCode(taskKeyPressed)),
              Expanded(
                child: ListView.builder(
                  itemCount: codeRemember.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Text(prettyCode(codeRemember[index]));
                  },
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
      ),
    );
  }

  String prettyCode(list) {
    return list.join(" ");
  }

  void startTask() {
    socketIoClient.socket.on('taskCodeToFound', (data) {
      taskCodeToFound = data;
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

    socketIoClient.socket.on('taskCompletedTaskKeyCode', (data) {
      if (mounted) {
        setState(() {
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data['game'];
        });
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
          'stopTask', {'task': widget.task, 'player': currentPlayer});

      updateCurrentPlayer(data['isAlive'], data['isDeadReport']);

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
    });

    socketIoClient.socket.on('taskKeyPressed', (data) {
      if (taskKeyPressed.length > 3) {
        if (mounted) {
          setState(() {
            codeRemember.add(taskKeyPressed);
          });
        }
        taskKeyPressed = [];
      }
      taskKeyPressed.add(data);
    });

    socketIoClient.socket.emit(
      "startTask",
      {
        'task': widget.task,
        "player": currentPlayer,
      },
    );
    startTimer();
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
    // }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        // print("LEFT TIMER === $_start ");
        if (_start == 0) {
          print("timer key code done");

          socketIoClient.socket.emit("timerTaskDone", {
            "macPlayer": currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty) {
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
