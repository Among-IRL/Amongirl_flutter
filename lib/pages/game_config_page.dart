import 'package:amoungirl/pages/end_game_page.dart';
import 'package:amoungirl/pages/roles_allocation.dart';
import 'package:amoungirl/pages/task_page.dart';
import 'package:amoungirl/pages/vote_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GameConfigPage extends StatefulWidget {
  static const routeName = 'game_config';

  @override
  State<StatefulWidget> createState() => GameConfigPageState();
}

class GameConfigPageState extends State<GameConfigPage> {
  TextEditingController room1Controller = TextEditingController();
  TextEditingController room2Controller = TextEditingController();
  TextEditingController room3Controller = TextEditingController();
  TextEditingController room4Controller = TextEditingController();

  TextEditingController player1Controller = TextEditingController();
  TextEditingController player2Controller = TextEditingController();
  TextEditingController player3Controller = TextEditingController();
  TextEditingController player4Controller = TextEditingController();

  final GlobalKey<FormState> _formKeyRoom = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKeyPlayer = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    room1Controller.dispose();
    room2Controller.dispose();
    room3Controller.dispose();
    room4Controller.dispose();
    player1Controller.dispose();
    player2Controller.dispose();
    player4Controller.dispose();
    player4Controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Création de jeu"),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                roomCreation(),
                playerCreation(),
                ElevatedButton(
                  onPressed: () {
                    //todo configurer game
                    print("configurer game");
                    getAllRoom();
                    getAllPlayer();
                  },
                  child: Text('Configurer game'),
                ),
                ElevatedButton(
                  onPressed: () {
                    //todo start game
                    print("start game");
                    Navigator.of(context).pushNamed(RoleAllocationPage.routeName);

                  },
                  child: Text("Start"),
                ),
              ],
            )),
      ),
    );
  }

  Widget roomCreation() {
    return Row(
      children: [
        Form(
          key: _formKeyRoom,
          child: Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text('Entrez les salles de jeux'),
                ),
                TextFormField(
                  controller: room1Controller,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: "Salon", labelText: "Salle 1"),
                ),
                TextFormField(
                  controller: room2Controller,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: "Cuisine", labelText: "Salle 2"),
                ),
                TextFormField(
                  controller: room3Controller,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: "Salle à manger", labelText: "Salle 3"),
                ),
                TextFormField(
                  controller: room4Controller,
                  decoration: kTextFieldDecoration.copyWith(
                      hintText: "Grenier", labelText: "Salle 4"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget playerCreation() {
    return Row(
      children: [
        Form(
          key: _formKeyPlayer,
          child: Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text('Entrez les joueurs'),
                ),
                TextFormField(
                  controller: player1Controller,
                  decoration:
                      kTextFieldDecoration.copyWith(labelText: "Joueur 1"),
                ),
                TextFormField(
                  controller: player2Controller,
                  decoration:
                      kTextFieldDecoration.copyWith(labelText: "Joueur 2"),
                ),
                TextFormField(
                  controller: player3Controller,
                  decoration:
                      kTextFieldDecoration.copyWith(labelText: "Joueur 3"),
                ),
                TextFormField(
                  controller: player4Controller,
                  decoration:
                      kTextFieldDecoration.copyWith(labelText: "Joueur 4"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> getAllRoom() {
    return [
      room1Controller.text,
      room2Controller.text,
      room3Controller.text,
      room4Controller.text,
    ];
  }
  List<String> getAllPlayer() {
    return [
      player1Controller.text,
      player2Controller.text,
      player3Controller.text,
      player4Controller.text,
    ];
  }
}
