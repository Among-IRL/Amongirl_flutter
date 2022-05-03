import 'dart:async';

import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoleAllocationPage extends StatefulWidget {
  static const routeName = 'role_allocation';

  @override
  State<StatefulWidget> createState() => RoleAllocationPageState();
}

class RoleAllocationPageState extends State<RoleAllocationPage> {

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
          setState(() {
            print("timer done");
            Navigator.of(context).pushNamed(TaskPage.routeName);
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
        body: Center(child: Text('Votre role est IMPOSTEUR')));
  }
}
