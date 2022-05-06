import 'dart:async';

import 'package:amoungirl/pages/game_config_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EndGamePage extends StatefulWidget {
  final String role;

  EndGamePage(this.role);

  static const routeName = 'end_game';

  @override
  State<StatefulWidget> createState() => EndGamePageState();
}

class EndGamePageState extends State<EndGamePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late Timer _timer;
  int _start = 5;

  @override
  void initState() {
    startTimer();
    cleanSharedPref();
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
          title: const Text("Fin"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("${widget.role} à gagné !"),
            ],
          ),
        ));
  }

  cleanSharedPref()async {
    final SharedPreferences prefs = await _prefs;
    await prefs.clear();
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
                builder: (BuildContext context) => GameConfigPage(),
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
}
