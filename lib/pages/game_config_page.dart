import 'dart:convert';
import 'dart:io';

import 'package:amoungirl/pages/roles_allocation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/socket_io_client.dart';

class GameConfigPage extends StatefulWidget {
  static const routeName = 'game_config';

  const GameConfigPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GameConfigPageState();
}

class GameConfigPageState extends State<GameConfigPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController pseudoController = TextEditingController();

  SocketIoClient socketIoClient = SocketIoClient();

  bool allReady = false;
  bool isReady = false;

  late String _pseudo;

  List<dynamic> players = [];

  @override
  void initState() {
    clearPrefs();

    if (Platform.isAndroid) {
      askConfig();
    }

    initializeSocket();
    socketIoClient.socket.emit('getGameData');
    print("inin game");

    super.initState();
  }

  @override
  void setState(fn) {
    if (mounted) {
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
              socketIoClient.socket.emit('resetGame');
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
                  if (mounted) {
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
    socketIoClient.socket.on('resetGame', (data) async {
      final SharedPreferences prefs = await _prefs;
      prefs.clear();
      if (mounted) {
        setState(() {
          players = data['players'];
          isReady = false;
        });
      }
    });

    socketIoClient.socket.on('getGameData', (data) async {
      print("INIT GAME");
      final SharedPreferences prefs = await _prefs;
      prefs.clear();
      print(prefs);
      if (mounted) {
        setState(() {
          players = data['players'];
        });
      }
    });

    socketIoClient.socket.on('startGame', (data) {
      print("data");
      print(data);
      if (mounted) {
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

    socketIoClient.socket.on('selectPlayer', (data) {
      print("select player");
      List dataPlayers = data["game"]['players'];
      if (mounted) {
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

    print("player['name'] = ${player['name']}");
    print("PLAYER == $player");
    if (player['name'] == pseudoController.text) {
      print("name == pref ok ?");
      await prefs.setString("currentPlayer", json.encode(player));
    }
  }

  choosePseudo() {
    if (pseudoController.text.isNotEmpty) {
      print(pseudoController.text);
      isReady = true;
      socketIoClient.socket
          .emit('selectPlayer', {'name': pseudoController.text});
    }
  }

  start() {
    socketIoClient.socket.emit('startGame');
  }

  void setRoleInPrefs(Map<String, dynamic> data) async {
    final SharedPreferences prefs = await _prefs;

    final current = prefs.getString("currentPlayer");
    if (current != null) {
      final player = json.decode(prefs.getString("currentPlayer")!);
      List<dynamic> players = data['players'];

      final dataPlayer =
          players.firstWhere((element) => element['mac'] == player['mac']);

      if (dataPlayer['role'] == "saboteur") {
        player['role'] = dataPlayer['role'];
        prefs.setString("currentPlayer", json.encode(player));
      }
    }
  }

  void clearPrefs() async {
    print(" \n !! CLEAR PREFS !! \n");
    final SharedPreferences prefs = await _prefs;
    prefs.clear();
  }

  void askConfig() async {
    var status = await Permission.location.status;
    if (status.isGranted) {
      return;
    } else {
      Map<Permission, PermissionStatus> status =
          await [Permission.location].request();
      print("status == $status");

      print(
          "Permission.location.isPermanentlyDenied = ${Permission.location.isDenied}");
      if (await Permission.location.isDenied) {
        print("is permanently denied");
        openAppSettings();
      }
    }
  }
}
