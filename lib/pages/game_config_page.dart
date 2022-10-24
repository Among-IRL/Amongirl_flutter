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
          padding: const EdgeInsets.only(top:15.0, bottom: 15.0, left: 10, right: 10),
          child: Column(
            children: [
              TextField(
                maxLength: 15,
                controller: pseudoController,
                onChanged: (newValue) {
                  setState(() {
                    _pseudo = newValue;
                  });
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

    socket.on('resetGame', (data) {
      setState(() {
        players = data['players'];
        isReady = false;
      });
    });

    socket.on('initGame', (data) {
      print("INIT GAME");
      setState(() {
        players = data['players'];
      });
    });

    socket.on('startGame', (data) {
      setState(() {
        players = data['players'];
        // print("playser in start = $players");
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RoleAllocationPage(data),
        ),
      );
    });

    socket.on('selectPlayer', (data) {
      print("select player");
      List dataPlayers = data['players'];
      setState(() {
        players = data['players'];
        allReady = dataPlayers.length >= 4;
      });
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

  Future savePlayerInStorage() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString("player", pseudoController.text);
  }

  choosePseudo() {
    if (pseudoController.text.isNotEmpty) {
      print(pseudoController.text);
      isReady = true;
      socket.emit('selectPlayer', {'name': pseudoController.text});
      savePlayerInStorage();
    }
  }

  start() {
    socket.emit('startGame');
  }
}
