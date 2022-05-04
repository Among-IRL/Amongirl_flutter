import 'package:amoungirl/pages/roles_allocation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class GameConfigPage extends StatefulWidget {
  static const routeName = 'game_config';

  @override
  State<StatefulWidget> createState() => GameConfigPageState();
}

class GameConfigPageState extends State<GameConfigPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  late IO.Socket socket;

  bool allSelected = false;

  bool choosePlayerDisabled = false;

  List<dynamic> players = [];

  String choosenPlayer = "";

  @override
  void initState() {
    initializeSocket();

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
        title: const Text("AMOUNG IRL"),
        actions: [
          IconButton(
            onPressed: () {
              socket.emit('resetGame');
              print("reset");
            },
            icon: Icon(Icons.replay),
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            buildRadioPlayers(),
            ElevatedButton(
              onPressed: choosePlayerDisabled ? null : () => choosePseudo(),
              child: Text('Choisir ce perso'),
            ),
            ElevatedButton(
                child: Text("START GAME"),
                onPressed: allSelected ? () => start() : null),
          ],
        ),
      ),
    );
  }

  void initializeSocket() {
    socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
        IO.OptionBuilder().setTransports(['websocket']).build());
    // socket = IO.io("http://192.168.1.18:3000",
    //     IO.OptionBuilder().setTransports(['websocket']).build());

    // socket.connect();

    socket.on('resetGame', (data) {
      setState(() {
        players = data['players'];
        // [
        //   {
        //     "name": "Antony",
        //     "mac": '',
        //     "role": "player",
        //     "report": false,
        //     "isAlive": true,
        //     "selected": true
        //   },
        //   {
        //     "name": "Jonathan",
        //     "mac": '',
        //     "role": "player",
        //     "report": false,
        //     "isAlive": true,
        //     "selected": true
        //   },
        //   {
        //     "name": "Sarah",
        //     "mac": '',
        //     "role": "saboteur",
        //     "report": false,
        //     "isAlive": true,
        //     "selected": false
        //   },
        //   {
        //     "name": "Brian",
        //     "mac": "0013a20041a72956",
        //     "role": "player",
        //     "report": false,
        //     "isAlive": true,
        //     "selected": true,
        //   }
        // ];
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
      //todo pass data


      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => RoleAllocationPage(data),
        ),
      );
    });

    socket.on('selectPlayer', (data) {
      List dataPlayers = data['players'];
      setState(() {
        players = data['players'];
        allSelected = dataPlayers.every((player) => player['selected']);
      });
    });
  }

   buildRadioPlayers() {
    return Expanded(
      child: Column(
        children:
        players.map((player) {
          if (!player['selected']) {
            return RadioListTile<String>(
              title: Text("${player['name']}"),
              groupValue: choosenPlayer,
              value: player['name'],
              onChanged: (value) {
                setState(() {
                  choosenPlayer = value as String;
                });
                print("choosen player = $choosenPlayer");
              },
            );
          }
          else{
            return Container();
          }
        }
        ).toList(),
      ),
    );
  }

  Future savePlayerInStorage() async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString("player", choosenPlayer);

    setState(() {
      choosePlayerDisabled = true;
    });
  }

  choosePseudo() {
    if (choosenPlayer.isNotEmpty) {
      socket.emit('selectPlayer', {'name': choosenPlayer});
      savePlayerInStorage();
    }
  }

  start() {
    socket.emit('startGame');
  }
}
