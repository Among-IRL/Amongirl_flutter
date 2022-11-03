import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:amoungirl/pages/tasks/cable.dart';
import 'package:amoungirl/pages/tasks/key_code.dart';
import 'package:amoungirl/pages/tasks/qr_code.dart';
import 'package:amoungirl/pages/tasks/simon.dart';
import 'package:amoungirl/pages/tasks/socles.dart';
import 'package:amoungirl/pages/tasks/swipe_card.dart';
import 'package:amoungirl/pages/vote_page.dart';
import 'package:amoungirl/services/socket_io_client.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:wifi_hunter/wifi_hunter_result.dart';

import 'end_game_page.dart';

class TaskPage extends StatefulWidget {
  final Map<String, dynamic> game;

  TaskPage(this.game);

  static const routeName = 'task';

  @override
  State<StatefulWidget> createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SocketIoClient socketIoClient = SocketIoClient();
  List<dynamic> personalTasks = [];
  Map<String, dynamic> currentPlayer = {};
  bool blur = false;
  bool blockTask = false;

  List<dynamic> alivePlayers = [];

  late Timer _timer;

  bool backup = false;

  @override
  void initState() {
    getAlivePlayers(widget.game['players']);
    whoIam();
    getPersonalTasks();
    print("ENABLED BACKUP = ${enabledBackup()}");
    if (!enabledBackup()) {
      _timer = Timer.periodic(const Duration(seconds: 2), (Timer t) async {
        await huntWiFis();
      });
    }
    onSocket();
    super.initState();
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
        if(mounted) {
          setState(() {
            wiFiHunterResult = wiFiHunterResults;
          });
        }
      }
    } on PlatformException catch (exception) {
      print(exception.toString());
    }

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {

    var playerToKill = wiFiHunterResult.results.firstWhereOrNull(
        (element) => getAllPlayersMac().contains(element.SSID));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Liste des taches"),
        leading: Switch(
          // This bool value toggles the switch.
          value: backup,
          activeColor: Colors.amber,
          onChanged: (bool value) {
            // This is called when the user toggles the switch.
            setState(() {
              backup = value;
            });
          },
        ),
      ),
      floatingActionButton: Wrap(
        direction: Axis.horizontal,
        children: [
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "sabotage",
              elevation: 10,
              onPressed: () {
                if (currentPlayer['role'] == "player") {
                  return;
                }
                print("sabotage");

                socketIoClient.socket.emit('sabotage', {'isSabotage': true});
              },
              child: const Icon(Icons.settings),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "kill",
              elevation: 10,
              onPressed: () {
                if (currentPlayer['role'] == "player") {
                  return;
                }
                if (backup || Platform.isIOS) {
                  _showMyDialog();
                } else {
                  print("player to kill = ${playerToKill?.SSID}");
                  isMacNearby(playerToKill)
                      ? killPlayer(playerToKill)
                      : showSnackBar();
                }
              },
              child: const Icon(Icons.power_off),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(10),
            child: FloatingActionButton(
              heroTag: "report",
              elevation: 10,
              onPressed: () {
                if (!currentPlayer['isAlive']) {
                  return;
                }
                socketIoClient.socket.emit('report', {
                  'name': currentPlayer['name'],
                  'macDeadPlayer': 'PLAYER2'
                });
              },
              child: const Icon(Icons.campaign),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            currentPlayer.isNotEmpty ? tasksList(personalTasks) : Container(),
            BackdropFilter(
              filter: blur
                  ? ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)
                  : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }

  Widget tasksList(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return Container(
          height: MediaQuery.of(context).size.height / 2,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15.0),
            child: Text("Pas de taches pour le moment"),
          ));
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: tasks.length,
      itemBuilder: (BuildContext context, int index) {
        final actualTask = tasks[index];
        WiFiHunterResultEntry? contain = wiFiHunterResult.results
            .firstWhereOrNull((element) => element.SSID == actualTask['mac']);
        return GestureDetector(
          onTap: () {
            isAccessTask(contain, actualTask)
                ? goToRightTasks(actualTask)
                : null;
          },
          child: Container(
            color: isAccessTask(contain, actualTask)
                ? Colors.green[100]
                : Colors.red[100],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        actualTask['name'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      actualTask['accomplished']
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                    ],
                  ),
                  Row(children: [
                    wiFiHunterResult.results.isNotEmpty
                        ? Text(formatDistanceToString(contain, actualTask))
                        : const Text("En préparation")
                  ])
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void killPlayer(player) {
    socketIoClient.socket.emit('deathPlayer', {'mac': player.SSID});
  }

  void killPlayerBackup(playerMac) {
    socketIoClient.socket.emit('deathPlayer', {'mac': playerMac});
  }

  bool isAccessTask(mac, actualTask) {
    return (!actualTask['accomplished'] && (isMacNearby(mac) || enabledBackup()) && !blockTask);
  }

  String formatDistanceToString(contain, actualTask) {
    return getDistanceToWifi(contain, actualTask) != null
        ? getDistanceToWifi(contain, actualTask)! + 'm'
        : 'Pas de wifi détecté';
  }

  bool isMacNearby(mac) {
    if (mac == null) {
      return false;
    }

    print("calculDistanceWifi(mac.level) ${calculDistanceWifi(mac.level)}");
    return calculDistanceWifi(mac.level) <= 2.0;
  }

  String? getDistanceToWifi(contain, actualTask) {
    if (contain != null) {
      return contain.SSID == actualTask['mac']
          ? calculDistanceWifi(contain.level).toStringAsFixed(1)
          : "";
    } else {
      return null;
    }
  }

  void onSocket() {
    socketIoClient.socket.on('task', (data) {
      final myTask =
          personalTasks.indexWhere((task) => task['mac'] == data['mac']);
      setStateIfMounted(() {
        personalTasks[myTask] = data;
      });
    });

    socketIoClient.socket.on('win', (data) {
      if (mounted) {
        print("mounted = $mounted");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => EndGamePage(data)),
          );
        });
      }
    });

    socketIoClient.socket.on('report', (data) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => VotePage(data),
        ),
      );
    });

    socketIoClient.socket.on('sabotage', (data) {
      setState(() {
        blur = data;
      });
    });

    socketIoClient.socket.on('taskCompletedDesabotage', (data) {
      setState(() {
        blur = false;
      });
    });

    socketIoClient.socket.on('buzzer', (data) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => VotePage(widget.game),
        ),
      );
    });

    socketIoClient.socket.on('deathPlayer', (data) {
      if(mounted) {
        setState(() {
          getAlivePlayers(data['players']);

          if(data['mac'] == currentPlayer['mac']) {
            updateCurrentPlayer(data['isAlive']);

            if(!data['isAlive']) {
              blockTask = true;
            }

            if (data['isDeadReport']) {
              blockTask = false;
            }
          }
        });
      }
    });
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    if(mounted) {
      setState(() {
        final current = prefs.getString("currentPlayer");
        print("CURRENT = $current");
        if(current == null){
          print("current est null");
        }else {
          currentPlayer = json.decode(prefs.getString("currentPlayer")!);
        }
      });
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  goToRightTasks(Map<String, dynamic> task) {
    switch (task["mac"]) {
      case "CARDSWIPE":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SwipeCard(task, currentPlayer),
          ),
        );
        break;
      case "KEYCODE":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => KeyCode(task, currentPlayer),
          ),
        );
        break;
      case "QRCODE":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => QrCode(task, currentPlayer),
          ),
        );
        break;
      case "SIMON":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Simon(task, currentPlayer),
          ),
        );
        break;
      case "CABLE":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Cable(task, currentPlayer),
          ),
        );
        break;
      case "SOCLE":
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => Socle(task, currentPlayer),
          ),
        );
        break;
    }
  }

  void getPersonalTasks() async {
    final SharedPreferences prefs = await _prefs;
    final currentPlayer = json.decode(prefs.getString("currentPlayer")!);
    List<Map<String, dynamic>> tasks = [];
    List<dynamic> players = widget.game['players'];
    Map<String, dynamic> player =
        players.firstWhere((player) => player['mac'] == currentPlayer['mac']);
    if(mounted) {
      setState(() {
        personalTasks = player['personalTasks'];
      });
    }
  }

  num calculDistanceWifi(int rssi) {
    int rssiToOneMetter = -44;
    double environmentalFactor = 2.3;
    double ratio = (rssiToOneMetter - rssi) / (10 * environmentalFactor);

    return pow(10, ratio);
  }

  showSnackBar() {
    const snackBar = SnackBar(
      content: Text('Vous êtes trop loin pour tuer !'),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool enabledBackup() {
    return backup || Platform.isIOS;
  }

  List<Widget> allPlayers() {
    List<Widget> fabPlayer = [];
    var players = getAlivePlayers(widget.game['players']);
    for (var p in players) {
      fabPlayer.add(FloatingActionButton.small(
        child: Text(p['name']),
        onPressed: () {
          killPlayerBackup(p['mac']);
        },
      ));
    }

    fabPlayer.add(FloatingActionButton.small(
      child: Text("REPORT"),
      onPressed: () {
        if (!currentPlayer['isAlive']) {
          return;
        }
        socketIoClient.socket.emit('report',
            {'name': currentPlayer['name'], 'macDeadPlayer': 'PLAYER2'});
      },
    ));

    fabPlayer.add(FloatingActionButton.small(
      child: Text("SABOTER"),
      onPressed: () {
        if (currentPlayer['role'] == "player") {
          return;
        }
        print("sabotage");

        socketIoClient.socket.emit('sabotage', {'isSabotage': true});
      },
    ));

    return fabPlayer;
  }

  List<String> getAllPlayersMac() {
    List<String> playersMac = [];

    for (var p in alivePlayers) {
      playersMac.add(p['mac']);
    }

    print("PLAYER MAC == ${playersMac}");
    return playersMac;
  }

  getAlivePlayers(List<dynamic> allPlayers) {
    final players = allPlayers
        .where((player) =>
            player['isAlive'] == true && player['role'] != 'saboteur')
        .toList();
    if(mounted) {
      setState(() {
        alivePlayers = players;
      });
    }
  }

  updateCurrentPlayer(isAlive) async {
    final SharedPreferences prefs = await _prefs;
    final current = prefs.getString("currentPlayer");
    if(current != null){
      final currentDecoded = json.decode(current);
      currentDecoded['isAlive'] = isAlive;
      prefs.setString("currentPlayer", json.encode(currentDecoded));
      if(mounted){
        setState(() {
          currentPlayer = currentDecoded;
        });
      }
    }
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tuer un joueur'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Qui voulez-vous tuer ?'),
              ],
            ),
          ),
          actions: getButtonForAlivePlayers(),
        );
      },
    );
  }

  List<Widget> getButtonForAlivePlayers() {
    List<Widget> buttonAlivePlayers = [];

    for (var p in alivePlayers) {
      buttonAlivePlayers.add(
        ElevatedButton(
            onPressed: () {
              killPlayerBackup(p['mac']);
              Navigator.of(context).pop();
            },
            child: Text(p['name'])),
      );
    }
    return buttonAlivePlayers;
  }
}
