import 'dart:async';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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

  var taskKeyPressed = [];

  Map<String, dynamic> game = {};

  var taskCodeToFound = [];
  // var displayCode = ["*", "*", "*", "*"];

  List<List<dynamic>> codeRemember = [[]];

  late Timer _timer;
  int _start = 60;

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

    socketIoClient.socket.on('taskCompletedTaskKeyCode', (data){
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

    socketIoClient.socket.on('deathPlayer', (data){
      if(data['mac'] == widget.currentPlayer['mac']) {
        socketIoClient.socket.emit('stopTask', {
          'task': widget.task,
          'macPlayer': widget.currentPlayer
        });
      }
    });

    socketIoClient.socket.on('taskKeyPressed', (data) {
      if (taskKeyPressed.length > 3) {
        setState(() {
          codeRemember.add(taskKeyPressed);
        });
        taskKeyPressed = [];
      }
      taskKeyPressed.add(data);
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
        // print("LEFT TIMER === $_start ");
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

            socketIoClient.socket.emit('stopTask', {
              'task': widget.task,
              'macPlayer': widget.currentPlayer
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
