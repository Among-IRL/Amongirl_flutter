import 'dart:async';
import 'dart:convert';

import 'package:amoungirl/config/config.dart';
import 'package:amoungirl/pages/task_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class VotePage extends StatefulWidget {
  final Map<String, dynamic> game;

  VotePage(this.game);

  static const routeName = 'vote';

  @override
  State<StatefulWidget> createState() => VotePageState();
}

class VotePageState extends State<VotePage> {
  late IO.Socket socket;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  Map<String, dynamic> currentPlayer = {};

  String left = "10";

  Map<String, dynamic> playerVoted = {};

  bool isVoted = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: widget.game["players"].length,
                    itemBuilder: (BuildContext context, int index) {
                      final player = widget.game["players"][index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: RadioListTile(
                              title: Text(player['name']),
                              value: player,
                              groupValue: playerVoted,
                              onChanged: (dynamic value) {
                                if (isVoted) {
                                  return null;
                                }
                                setState(() {
                                  playerVoted = value;
                                });
                              },
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
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isVoted = true;
                    });
                    socket.emit('vote', {
                      'macFrom': currentPlayer['mac'],
                      'macTo': playerVoted['mac']
                    });
                  },
                  child: Text('VOTER'),
                ),
              ],
            ),
          ),
        ));
  }

  void onSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());
    socket = IO.io("http://${ip_address}:3000",
        IO.OptionBuilder().setTransports(['websocket']).build());

    // socket.connect();

    socket.on('meeting', (data) {
      setStateIfMounted(() {
        left = data['countDown'].toString();
      });
      if (data['countDown'] == 0) {
        print("dernier countdown = ${data}");

        displayDeadPlayerModal(data['vote'], data['count']);
        socket.clearListeners();
        // Navigator.pushReplacement(
        //         //   context,
        //         //   MaterialPageRoute(
        //         //     builder: (BuildContext context) => TaskPage(widget.game),
        //         //   ),
        //         // );
      }
    });
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    print("before get player");
    setState(() {
      currentPlayer = json.decode(prefs.getString("currentPlayer")!);
    });
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
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => TaskPage(widget.game),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
