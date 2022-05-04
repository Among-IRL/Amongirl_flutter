import 'dart:async';

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

  late Timer _timer;
  int _start = 3;

  @override
  void initState() {
    print("data in 2 =${widget.game}");
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
          setState(() {
            print("timer done");

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => TaskPage(widget.game),
              ),
            );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Création de jeu"),
        ),
        body: Center(child: Text('Votre role est $role')));
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    final localPlayer = await prefs.getString("player");
    final dataList = widget.game['players'].toList();

    final me = dataList.firstWhere((player) =>
    player['name'] == localPlayer);
    setState(() {
      role = me['role'];
    });
  }
}
