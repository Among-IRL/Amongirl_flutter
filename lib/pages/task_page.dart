import 'package:amoungirl/pages/end_game_page.dart';
import 'package:amoungirl/pages/vote_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:socket_io_client/socket_io_client.dart" as IO;

class TaskPage extends StatefulWidget {
  final Map<String, dynamic> game;

  TaskPage(this.game);

  static const routeName = 'task';

  @override
  State<StatefulWidget> createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late IO.Socket socket;
  List<dynamic> tasks = [];

  String pseudo = "";

  @override
  void initState() {
    whoIam();
    setState(() {
      tasks = widget.game['rooms'];
      print("tasks in init = $tasks");
    });
    onSocket();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final keys = tasks.keys.toList();
    // final values = tasks.values.toList();
    return Scaffold(
        appBar: AppBar(
          title: const Text("Liste des taches"),
          actions: [
            IconButton(
              onPressed: () {
                socket.emit('task', {'mac': '0013A20041A72956', 'status': true});
              },
              icon: Icon(Icons.build),
            ),
            IconButton(
              onPressed: () {
                socket.emit('win');
              },
              icon: Icon(Icons.emoji_events),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 10,
          onPressed: () {
            print("report");
            socket.emit('report', {'name': pseudo});
            Navigator.of(context).pushNamed(VotePage.routeName);
          },
          child: Icon(Icons.campaign),
        ),
        body: Center(
            child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (BuildContext context, int index) {
            // final keyActual = keys[index];
            // final actualValue = values[index];
            final actualTask = tasks[index];
            return Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    actualTask['name'],
                    style: TextStyle(fontSize: 20),
                  ),
                  actualTask['task']
                      ? Icon(
                          Icons.check,
                          color: Colors.green,
                        )
                      : Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                ],
              ),
            );
          },
        )));
  }

  void onSocket() {
    // socket = IO.io("https://amoung-irl-server-game.herokuapp.com/",
    //     IO.OptionBuilder().setTransports(['websocket']).build());
    socket = IO.io("http://192.168.1.18:3000",
        IO.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();

    socket.on('connect', (data) {
      // socket.emit('startGame');
      print("socket connect ${socket.connected}");
    });

    socket.on('task', (data) {
      print("data ${data}");
      final myTask = tasks.indexWhere((task) => task['mac'] == data['mac']);
      print("mystask = $myTask");
      setState(() {
        tasks[myTask] = data;
      });
    });
    
    socket.on('win', (data) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => EndGamePage(data['role']),
        ),
      );
    });



    // socket.on
  }

  Future whoIam() async {
    final SharedPreferences prefs = await _prefs;
    final localPlayer = await prefs.getString("player");
    setState(() {
      pseudo = localPlayer!;
    });
  }
}
