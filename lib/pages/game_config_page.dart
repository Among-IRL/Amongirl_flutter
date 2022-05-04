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

  bool allSelected = false;

  bool choosePlayerDisabled = false;

  late IO.Socket socket;
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
    socket = IO.io("http://10.57.29.158:3000",
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();
    print("socket connect ${socket.connected}");

    socket.on('connect', (data) {
      socket.emit('initGame');
    });

    socket.on('initGame', (data) {
      setState(() {
        players = data['players'];
      });
      print("liste de players $players");
    });

    socket.on('startGame', (data) {});

    socket.on('selectPlayer', (data) {
      print("ici");

      List dataPlayers = data['players'];
      setState(() {
        players = data['players'];
        allSelected = dataPlayers.every((player) => player['selected']);
        print('all selcted = $allSelected');
      });
    });
  }

  Widget buildRadioPlayers() {
    List<Widget> playersRadio = [];
    for (final player in players) {
      if (!player['selected']) {
        Widget r = Radio(
          visualDensity: VisualDensity.compact,
          value: player['name'],
          groupValue: choosenPlayer,
          onChanged: (value) {
            setState(() {
              choosenPlayer = value as String;
            });
            print("choosen player = $choosenPlayer");
          },
        );
        Widget t = Text(player['name']);
        playersRadio.add(r);
        playersRadio.add(t);
      }
    }
    return Column(
      children: [
        Row(
          children: playersRadio,
        ),
      ],
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
    print("choisir ce pseudo = ");
    if (choosenPlayer.isNotEmpty) {
      socket.emit('selectPlayer', {'name': choosenPlayer});
      savePlayerInStorage();
    }
  }

  start() {
    print("press");
    socket.emit('startGame');
    Navigator.of(context).pushNamed(RoleAllocationPage.routeName);
  }
}
