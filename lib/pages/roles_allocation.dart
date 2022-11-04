import 'dart:async';

import 'package:amoungirl/pages/task_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoleAllocationPage extends StatefulWidget {
  final Map<String, dynamic> game;
  final Map<String, dynamic> currentPlayer;

  RoleAllocationPage(
    this.game,
    this.currentPlayer,
  );

  static const routeName = 'role_allocation';

  @override
  State<StatefulWidget> createState() => RoleAllocationPageState();
}

class RoleAllocationPageState extends State<RoleAllocationPage> {

  String role = "";
  String name = "";

  late Timer _timer;
  int _start = 3;

  @override
  void initState() {
    startTimer();
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
              builder: (BuildContext context) => TaskPage(widget.game, widget.currentPlayer, false),
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
              '${widget.currentPlayer['name']}, votre role est :',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              '${widget.currentPlayer['role']}',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: (widget.currentPlayer['role'] == "player")
                      ? Colors.green
                      : Colors.red),
            ),
          ],
        )));
  }

  // Future whoIam() async {
  //   final SharedPreferences prefs = await _prefs;
  //   if (mounted) {
  //     setState(() {
  //       //FIXME = regarder si le current existe dabord
  //       final current = json.decode(prefs.getString("currentPlayer")!);
  //       if (current != null) {
  //         currentPlayer = json.decode(prefs.getString("currentPlayer")!);
  //       }
  //     });
  //   }
  // }
}
