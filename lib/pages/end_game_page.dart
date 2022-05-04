import 'dart:async';

import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EndGamePage extends StatefulWidget {
  final String role;

  EndGamePage(this.role);

  static const routeName = 'end_game';

  @override
  State<StatefulWidget> createState() => EndGamePageState();
}

class EndGamePageState extends State<EndGamePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
}
