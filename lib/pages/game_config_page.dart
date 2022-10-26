import 'dart:convert';
import 'dart:math';

import 'package:amoungirl/config/config.dart';
import 'package:amoungirl/pages/roles_allocation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class GameConfigPage extends StatefulWidget {
  static const routeName = 'game_config';

  const GameConfigPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GameConfigPageState();
}

class GameConfigPageState extends State<GameConfigPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController pseudoController = TextEditingController();

  late IO.Socket socket;

  bool allReady = false;
  bool isReady = false;

  late String _pseudo;

  List<dynamic> players = [];

  @override
  void initState() {
    initializeSocket();
    socket.emit('initGame');
    print("inin game");

    super.initState();
  }

  @override
  void setState(fn) {
    if(mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AMONG IRL"),
        actions: [
          IconButton(
            onPressed: () {
              socket.emit('resetGame');
            },
            icon: const Icon(Icons.replay),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(
              top: 15.0, bottom: 15.0, left: 10, right: 10),
          child: Column(
            children: [
              TextField(
                maxLength: 15,
                controller: pseudoController,
                onChanged: (newValue) {
                  if(mounted) {
                    setState(() {
                      _pseudo = newValue;
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: 'Taper votre pseudo ...',
                ),
              ),
              Divider(),
              buildPlayersList(),
              ElevatedButton(
                  child: const Text("READY"),
                  onPressed: pseudoController.text.length >= 3 && !isReady
                      ? () => choosePseudo()
                      : null),
              ElevatedButton(
                  child: const Text("START GAME"),
                  onPressed: allReady ? () => start() : null),
            ],
          ),
        ),
      ),
    );
  }

  void initializeSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());
    socket = IO.io("http://${ip_address}:3000",
        IO.OptionBuilder().setTransports(['websocket']).build());

    // socket.connect();

    socket.on('resetGame', (data) async {
      final SharedPreferences prefs = await _prefs;
      prefs.clear();
      if(mounted) {
        setState(() {
          players = data['players'];
          isReady = false;
        });
      }
    });

    socket.on('initGame', (data) async {
      print("INIT GAME");
      final SharedPreferences prefs = await _prefs;
      prefs.clear();
      print(prefs);
      if(mounted){
        setState(() {
          players = data['players'];
        });
      }

    });

    socket.on('startGame', (data) {
      print("data");
      print(data);
      if(mounted) {
        setState(() {
          players = data['players'];
          // print("playser in start = $players");
        });
      }

      setRoleInPrefs(data);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RoleAllocationPage(data)),
            (Route<dynamic> route) => false,
      );

    });

    socket.on('selectPlayer', (data) {
      print("select player");
      List dataPlayers = data["game"]['players'];
      if(mounted){
        setState(() {
          players = data['game']['players'];
          allReady = dataPlayers.length >= 3;
        });
      }

      print("data == $data");
      savePlayerInStorage(data['currentPlayer']);
    });

  }

  buildPlayersList() {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: players.length + 1,
        itemBuilder: (BuildContext context, int index) {
          if (index != players.length) {
            return ListTile(
              leading: const Icon(Icons.check),
              title: Text(players[index]['name']),
            );
          } else {
            return const SizedBox(
              height: 50,
            );
          }
        },
      ),
    );
  }

  Future savePlayerInStorage(Map<String, dynamic> player) async {
    final SharedPreferences prefs = await _prefs;
    if (player['name'] == pseudoController.text) {
      await prefs.setString("currentPlayer", json.encode(player));
    }
  }

  choosePseudo() {
    if (pseudoController.text.isNotEmpty) {
      print(pseudoController.text);
      isReady = true;
      socket.emit('selectPlayer', {'name': pseudoController.text});
    }
  }

  start() {
    socket.emit('startGame');
  }

  void setRoleInPrefs(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await _prefs;

    final player = json.decode(prefs.getString("currentPlayer")!);
    List<dynamic> players = data['players'];

    final dataPlayer = players.firstWhere((element) => element['mac'] == player['mac']);

    if(dataPlayer['role'] == "saboteur") {
      player['role'] = dataPlayer['role'];
      prefs.setString("currentPlayer", json.encode(player));
    }
  }
}
