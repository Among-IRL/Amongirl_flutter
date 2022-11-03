import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoleAllocationPage extends StatefulWidget {
  final Map<String, dynamic> game;

  RoleAllocationPage(this.game);

  static const routeName = 'role_allocation';

  @override
  State<StatefulWidget> createState() => RoleAllocationPageState();
}

class RoleAllocationPageState extends State<RoleAllocationPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  String role = "";
  String name = "";
  Map<String, dynamic> currentPlayer = {};

  late Timer _timer;
  int _start = 3;

  @override
  void initState() {
    startTimer();
    whoIam();
    super.initState();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          print("timer role done");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => TaskPage(widget.game),
            ),
          );

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Attribution des rôles"),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${currentPlayer['name']}, votre role est :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              '${currentPlayer['role']}',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: (currentPlayer['role'] == "player")
                      ? Colors.green
                      : Colors.red),
            ),
          ],
        )));
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    if (mounted) {
      setState(() {
        currentPlayer = json.decode(prefs.getString("currentPlayer")!);
        print("current player = $currentPlayer");
      });
    }

  }
}
