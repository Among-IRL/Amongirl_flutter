import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amoungirl/config/config.dart';
import 'package:amoungirl/pages/end_game_page.dart';
import 'package:amoungirl/pages/game_config_page.dart';
import 'package:amoungirl/pages/task_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:wifi_hunter/wifi_hunter_result.dart';
import 'package:collection/collection.dart';

import '../services/socket_io_client.dart';

class DeathPlayerPage extends StatefulWidget {
  final Map<String, dynamic> game;

  DeathPlayerPage(this.game);

  static const routeName = 'death';

  @override
  State<StatefulWidget> createState() => DeathPlayerPageState();
}

class DeathPlayerPageState extends State<DeathPlayerPage> {
  SocketIoClient socketIoClient = SocketIoClient();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();

  Map<String, dynamic> currentPlayer = {};

  String left = "10";

  Map<String, dynamic> playerVoted = {};

  bool isVoted = false;

  bool win = false;

  String whoWin = "";

  List<String> namePlayers = ['PLAYER1', 'PLAYER2', 'PLAYER3', 'PLAYER4'];

  String value = "";

  bool showList = false;

  late Timer _timer;

  late List<dynamic> players;

  @override
  void initState() {
    onSocket();
    whoIam();
    if(Platform.isAndroid) {
      _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
        await huntWiFis();
      });
    }
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
    _timer.cancel();
    super.dispose();
  }

  Future<void> huntWiFis() async {
    try {
      final wiFiHunterResults = (await WiFiHunter.huntWiFiNetworks)!;
      if (wiFiHunterResults != wiFiHunterResult &&
          wiFiHunterResults.results.isNotEmpty) {
        setState(() {
          wiFiHunterResult = wiFiHunterResults;
        });
      }

    } on PlatformException catch (exception) {
      print(exception.toString());
    }

    if (!mounted) return;
  }


  @override
  Widget build(BuildContext context) {
    if(currentPlayer.isEmpty){
      return Container();
    }
    final alivePlayers = getAlivePlayers();
    var playerToKill = wiFiHunterResult.results
        .firstWhereOrNull((element) => namePlayers.contains('PLAYER1'));
    return Scaffold(
        appBar: AppBar(
          title: const Text("Vote"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => TaskPage(widget.game, false)),
                                (Route<dynamic> route) => false,
                          );

                        },
                        child: Text('Retour'),
                      ),
                    ],
                  ),
                ),

                Text("C'est la réu les gars, il est temps de tuer du boug"),
                Expanded(
                  child: showList ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: alivePlayers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final player = alivePlayers[index];
                      return GestureDetector(
                        onTap: () {
                          killPlayer();
                        },
                        child: Container(
                          child: Padding(
                            padding:  const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(player['name']
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ) : Container(),
                ),
                Text(value),
                isVoted
                    ? Text('Vous avez voter pour ${playerVoted['name']}')
                    : Container(),
                currentPlayer['isAlive'] ?
                ElevatedButton(
                  onPressed: () {
                    isMacNearby(playerToKill) ? killPlayer() : null;
                  },
                  child: Text('Kill'),
                ) : Container(),

                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showList = true;
                    });
                  },
                  child: Text('List'),
                ),
              ],
            ),
          ),
        ));
  }

  void killPlayer() {
    print('PLAYER1');
    socketIoClient.socket.emit('deathPlayer', {
      'mac': 'PLAYER1'
    });
  }

  bool isMacNearby(mac) {
    if(mac == null) {
      return false;
    }

    return calculDistanceWifi(mac.level) <= 0.5;
  }


  num calculDistanceWifi(int rssi) {
    int rssiToOneMetter = -44;
    double environmentalFactor = 2.3;
    double ratio = (rssiToOneMetter - rssi) / (10 * environmentalFactor);

    return pow(10, ratio);
  }

  void onSocket() {
    socketIoClient.socket.on('win', (data) {
      print(data);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => EndGamePage(data)),
      );

      setState(() {
        win = true;
      });
    });
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      currentPlayer = json.decode(prefs.getString("currentPlayer")!);
    });
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  List<dynamic> getAlivePlayers() {
    setState(() {
      players = widget.game["players"];
    });
    return players.where((player) => player['isAlive'] == true && player['role'] != 'saboteur').toList();
  }
}
