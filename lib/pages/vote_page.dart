import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/config/config.dart';
import 'package:amoungirl/pages/end_game_page.dart';
import 'package:amoungirl/pages/game_config_page.dart';
import 'package:amoungirl/pages/task_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/socket_io_client.dart';

class VotePage extends StatefulWidget {
  final Map<String, dynamic> game;

  VotePage(this.game);

  static const routeName = 'vote';

  @override
  State<StatefulWidget> createState() => VotePageState();
}

class VotePageState extends State<VotePage> {
  SocketIoClient socketIoClient = SocketIoClient();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic> currentPlayer = {};

  String left = "10";

  Map<String, dynamic> playerVoted = {};

  bool isVoted = false;

  bool win = false;

  String whoWin = "";


  // late Timer _timer;
  // int _start = 10;

  String value = "";

  @override
  void initState() {
    onSocket();
    whoIam();

    super.initState();
  }

  @override
  void dispose() {
    print("dispose");

    // _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(currentPlayer.isEmpty){
      return Container();
    }
    final alivePlayers = getAlivePlayers();
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
                Text("C'est la réu les gars, il est temps de tuer du boug"),
                Text(
                  "$left secondes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: alivePlayers.length,
                    itemBuilder: (BuildContext context, int index) {
                      final player = alivePlayers[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: currentPlayer['isAlive'] ? RadioListTile(
                              title: Text(player['name']),
                              value: player,
                              groupValue: playerVoted,
                              onChanged: (dynamic value) {
                                if (isVoted) {
                                  return;
                                }
                                if(mounted) {
                                  setState(() {
                                    playerVoted = value;
                                  });
                                }
                              },
                            )
                              : ListTile(
                                title: Text(player['name'])
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
                Text(value),
                isVoted
                    ? Text('Vous avez voter pour ${playerVoted['name']}')
                    : Container(),
                currentPlayer['isAlive'] ?
                ElevatedButton(
                  onPressed: !isVoted ? () {
                    if(mounted) {
                      setState(() {
                        isVoted = true;
                      });
                    }
                    socketIoClient.socket.emit('vote', {
                      'macFrom': currentPlayer['mac'],
                      'macTo': playerVoted['mac']
                    });
                  } : null,
                  child: Text('VOTER'),
                ) : Container(),
              ],
            ),
          ),
        ));
  }

  void onSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());

    socketIoClient.socket.on('meeting', (data) async {
      setStateIfMounted(() {
        left = data['countDown'].toString();
      });

      if (data['countDown'] == 0) {

        print("dernier countdown = ${data}");

        displayDeadPlayerModal(data['vote'], data['count']);

        await Future.delayed(Duration(seconds: 5));
        Navigator.of(context).pop();

        if (win) {
          print("on win");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => EndGamePage(whoWin)),
            (Route<dynamic> route) => false,
          );
        } else {
          print("on win pas");
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => TaskPage(widget.game)),
            (Route<dynamic> route) => false,
          );
        }
        socketIoClient.socket.clearListeners();
      }

    });


    socketIoClient.socket.on('deathPlayer', (dataDeath) async {
      final SharedPreferences prefs = await _prefs;
      final currentPlayer = json.decode(prefs.getString("currentPlayer")!);
      if(dataDeath["mac"] == currentPlayer['mac']){
        currentPlayer["isAlive"] = dataDeath["isAlive"];
        await prefs.setString("currentPlayer", json.encode(currentPlayer));
      }
    });

    socketIoClient.socket.on('win', (data) {
      print('data win in vote page=$data');
      if(mounted) {
        setState(() {
          win = true;
          whoWin = data;
        });
      }
    });
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    if(mounted) {
      setState(() {
        currentPlayer = json.decode(prefs.getString("currentPlayer")!);
      });
    }
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  Future<void> displayDeadPlayerModal(String vote, int count) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Joueur éliminé'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                vote.isEmpty
                    ? Text("Aucun joueur n'a été éliminé")
                    : Text('Le joueur $vote a été éliminé avec $count votes'),
              ],
            ),
          ),
        );
      },
    );
  }

  List<dynamic> getAlivePlayers() {
    List<dynamic> players = widget.game["players"];
    return players.where((player) => player['isAlive'] == true).toList();
  }
}
