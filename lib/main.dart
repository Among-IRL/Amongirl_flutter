import 'package:amoungirl/pages/end_game_page.dart';
import 'package:amoungirl/pages/game_config_page.dart';
import 'package:amoungirl/pages/roles_allocation.dart';
import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/pages/vote_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        GameConfigPage.routeName: (context) => GameConfigPage(),
        RoleAllocationPage.routeName: (context) => RoleAllocationPage(),
        TaskPage.routeName: (context) => TaskPage(),
        VotePage.routeName: (context) => VotePage(),
        EndGamePage.routeName: (context) => EndGamePage(),
      },
      home: GameConfigPage(),
    );
  }
}
