import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  var taskCodeToFound = [];

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
        title: Text("Code"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            children: [
              Text("Veuillez entrer le code qui vous à été donné"),
              Text("Temps restant : $_start"),
              Text("Le code a rentrer est :"),
              Text(taskCodeToFoundToString(taskCodeToFound), style: TextStyle(fontSize: 50),),
              Form(
                onChanged: () => codeChanged(),
                child: Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for(var element in taskKeyPressed) SizedBox(
                        width: 50,
                        child: TextFormField(
                          maxLength: 1,
                          initialValue: element,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String taskCodeToFoundToString(taskCodeToFound) {
    return taskCodeToFound.join(" ");
  }
  void startTask() {
    socketIoClient.socket.on('taskCodeToFound', (data) {
      taskCodeToFound = data;
    });

    socketIoClient.socket.on('taskKeyPressed', (data) {
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
        print("LEFT TIMER === $_start ");
        if (_start == 0) {
          setState(() {
            print("timer key code done");

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

  codeChanged() {
    //TODO : EMIT CODE CHANGE
    print("EMIT CODE CHANGE");
  }
}
