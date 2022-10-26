import 'package:flutter/material.dart';

import '../services/socket_io_client.dart';

class TaskLoadingPage extends StatefulWidget {

  static const routeName = 'taskLoadingPage';

  @override
  State<StatefulWidget> createState() => TaskLoadingPageState();
}

class TaskLoadingPageState extends State<TaskLoadingPage> {
  SocketIoClient socketIoClient = SocketIoClient();

  String left = "10";
  bool isTimerFinished = true;

  @override
  void initState() {
    //onSocket();
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text("Temps avant de pouvoir confirmer la tâche"),
                  Text(
                    "$left secondes",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: isTimerFinished ? () => {} :  null,
                child: const Text('Vailder'),
              ),
            ],
          ),
        ));
  }

  void onSocket() {
    // socketIoClient.socket.on('meeting', (data) {
    //   print("toto");
    //   print("data in meeting $data");
    //
    //   setStateIfMounted(() {
    //     left = data['countDown'].toString();
    //     print("LEFT = $left");
    //   });
    //   if(data['countDown'] == 0){
    //     socket.clearListeners();
    //     Navigator.pushReplacement(
    //       context,
    //       MaterialPageRoute(
    //         builder: (BuildContext context) => TaskPage(widget.game),
    //       ),
    //     );
    //   }
    // });
  }

  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }
}
