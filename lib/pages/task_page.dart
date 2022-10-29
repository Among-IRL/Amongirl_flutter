import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:amoungirl/pages/tasks/cable.dart';
import 'package:amoungirl/pages/tasks/key_code.dart';
import 'package:amoungirl/pages/tasks/qr_code.dart';
import 'package:amoungirl/pages/tasks/simon.dart';
import 'package:amoungirl/pages/tasks/swipe_card.dart';
import 'package:amoungirl/pages/vote_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/socket_io_client.dart';

class TaskPage extends StatefulWidget {
  final Map<String, dynamic> game;

  TaskPage(this.game);

  static const routeName = 'task';

  @override
  State<StatefulWidget> createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SocketIoClient socketIoClient = SocketIoClient();
  List<dynamic> personalTasks = [];
  Map<String, dynamic> currentPlayer = {};
  bool blur = false;

  late Timer _timer;

  //FIXME: change time
  int _start = 5;

  @override
  void initState() {
    whoIam();
    getPersonalTasks();
    onSocket();
    super.initState();
  }

  @override
  void dispose() {
    // _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des taches"),
      ),
      floatingActionButton: Wrap(
        direction: Axis.horizontal,
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "sabotage",
              elevation: 10,
              onPressed: () {
                print("sabotage");
                // setState(() {
                //   blur = true;
                // });
                // startSabotageTimer();
                socketIoClient.socket.emit('sabotage', {'isSabotage': true});
              },
              child: const Icon(Icons.settings),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "kill",
              elevation: 10,
              onPressed: () {
                print("kill");
                // socket.emit('report', {'name': currentPlayer['name']});
              },
              child: const Icon(Icons.power_off),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "report",
              elevation: 10,
              onPressed: () {
                print("report");
                socketIoClient.socket
                    .emit('report', {'name': currentPlayer['name']});
              },
              child: const Icon(Icons.campaign),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(

          child: Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                currentPlayer.isNotEmpty ? tasksList(personalTasks) : Container(),
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
      ),
    );
  }

  Widget tasksList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return Container(
          height: MediaQuery.of(context).size.height / 2,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Text("Pas de taches pour le moment"),
          ));
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        // final keyActual = keys[index];
        // final actualValue = values[index];

        final actualTask = tasks[index];
        return GestureDetector(
          onTap: () {
            goToRightTasks(actualTask);
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      actualTask['name'],
                      style: const TextStyle(fontSize: 20),
                    ),
                    actualTask['accomplished']
                        ? const Icon(
                            Icons.check,
                            color: Colors.green,
                          )
                        : const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                  ],
                ),
                Row(
                  children: const [
                    Text("distance : 0"),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void onSocket() {
    socketIoClient.socket.on('task', (data) {
      final myTask =
          personalTasks.indexWhere((task) => task['mac'] == data['mac']);
      setStateIfMounted(() {
        personalTasks[myTask] = data;
      });
    });

    // socket.on('win', (data) {
    //   print('data win =$data');
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(
    //       builder: (BuildContext context) => EndGamePage(data),
    //     ),
    //   );
    // });

    socketIoClient.socket.on('report', (data) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => VotePage(data),
        ),
      );
    });

    socketIoClient.socket.on('sabotage', (data) {
      print("sabotage");
      setState(() {
        blur = data;
      });
    });

    socketIoClient.socket.on('buzzer', (data) {
      print('data buzzer =$data');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => VotePage(widget.game),
        ),
      );
    });

    // socket.on
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    print("before get player");
    setState(() {
      currentPlayer = json.decode(prefs.getString("currentPlayer")!);
      print("current player = $currentPlayer");
    });
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  goToRightTasks(Map<String, dynamic> task) {
    print("task['mac'] === ${task["mac"]}");
    switch (task["mac"]) {
      case "CARDSWIPE":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SwipeCard(task, currentPlayer),
          ),
        );
        break;
      case "KEYCODE":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => KeyCode(task),
          ),
        );
        break;
      case "QRCODE":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => QrCode(task),
          ),
        );
        break;
      case "SIMON":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Simon(task),
          ),
        );
        break;
      case "CABLE":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Cable(task),
          ),
        );
        break;
      case "SOCLE":
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Cable(task),
          ),
        );
        break;
    }
  }

  void getPersonalTasks() async {
    final SharedPreferences prefs = await _prefs;
    final currentPlayer = json.decode(prefs.getString("currentPlayer")!);
    List<Map<String, dynamic>> tasks = [];
    List<dynamic> players = widget.game['players'];
    Map<String, dynamic> player =
        players.firstWhere((player) => player['mac'] == currentPlayer['mac']);
    setState(() {
      personalTasks = player['personalTasks'];
    });
  }
//FIXME just for test
// void startSabotageTimer() {
//   const oneSec = Duration(seconds: 1);
//   _timer = Timer.periodic(
//     oneSec,
//         (Timer timer) {
//       if (_start == 0) {
//         setState(() {
//           print("timer done");
//           blur = false;
//           timer.cancel();
//         });
//       } else {
//         setState(() {
//           _start--;
//         });
//       }
//     },
//   );
// }
}
