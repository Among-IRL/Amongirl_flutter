import 'package:amoungirl/pages/vote_page.dart';
import 'package:amoungirl/widgets/text_field_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TaskPage extends StatefulWidget {
  static const routeName = 'task';

  @override
  State<StatefulWidget> createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  Map<String, bool> tasks = {
    "Cuisine : task1": true,
    "Salon : task2": true,
    "Grenier : task3": false,
    "Chambre : task4": true,
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keys = tasks.keys.toList();
    final values = tasks.values.toList();
    return Scaffold(
        appBar: AppBar(
          title: const Text("Liste des taches"),
        ),
        floatingActionButton: FloatingActionButton(
          elevation: 10,

          onPressed: () {
            print("report");
            Navigator.of(context).pushNamed(VotePage.routeName);
          },
          child: Icon(Icons.campaign),
        ),
        body: Center(
            child: ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (BuildContext context, int index) {
            final keyActual = keys[index];
            final actualValue = values[index];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(keyActual, style: TextStyle(fontSize: 20),),
                  actualValue ? Icon(Icons.check, color: Colors.green,) : Icon(Icons.close, color: Colors.red,),
                ],
              ),
            );
          },
        )));
  }
}
