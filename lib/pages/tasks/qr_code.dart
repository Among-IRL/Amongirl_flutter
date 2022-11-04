import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../end_game_page.dart';
import '../task_page.dart';
import '../vote_page.dart';

class QrCode extends StatefulWidget {
  final Map<String, dynamic> task;
  final Map<String, dynamic> currentPlayer;

  QrCode(this.task, this.currentPlayer);

  @override
  State<StatefulWidget> createState() => QrCodeState();
}

class QrCodeState extends State<QrCode> {
  SocketIoClient socketIoClient = SocketIoClient();

  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Map<String, dynamic> game = {};

  Map<String, dynamic> currentPlayer = {};

  String message = "";

  late Timer _timer;
  int _start = 10;

  bool blur = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    currentPlayer = widget.currentPlayer;
    startTask();
    super.initState();
  }

  @override
  void dispose() {
    controller?.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return Scaffold(
      appBar: AppBar(
        title: Text("Qr Code"),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Text("Temps restant : $_start"),
          ),
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                  borderColor: Colors.red,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: scanArea),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: (result != null)
                  ? Text(result!.code.toString())
                  : Column(
                      children: [
                        Text('Scan a code'),
                        Text(message),
                      ],
                    ),
            ),
          ),
          BackdropFilter(
            filter: blur
                ? ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)
                : ImageFilter.blur(sigmaX: 0.0, sigmaY: 0.0),
            child: Container(),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    bool test = false;
    controller.scannedDataStream.listen((scanData) {
      if (!test) {
        if (scanData.code == "MISSION ACCOMPLIE !") {
          test = true;
          socketIoClient.socket.emit(
            "qrCodeScan",
            {
              "player": currentPlayer,
              "accomplished": true,
            },
          );
        }
      }
    });

    this.controller?.pauseCamera();
    this.controller?.resumeCamera();
  }

  void startTask() {
    socketIoClient.socket.on("taskCompletedQrCode", (data) {
      if (mounted) {
        setState(() {
          message =
              "Tâche accomplie ! Veuillez rester le temps que le timer se termine";
          game = data['game'];
        });
      }
    });

    socketIoClient.socket.on('win', (data) {
      print('WIN');
      if (mounted) {
        print("mounted = $mounted");
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => EndGamePage(data)),
        );
      }
    });

    socketIoClient.socket.on('sabotage', (data) {
      if (mounted) {
        setState(() {
          blur = data;
        });
      }
    });

    socketIoClient.socket.on('taskCompletedDesabotage', (data) {
      if (mounted) {
        setState(() {
          blur = false;
        });
      }
    });

    socketIoClient.socket.on('taskNotComplete', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) =>
                TaskPage(data['game'], currentPlayer, blur),
          ),
        );
      }
    });

    socketIoClient.socket.on('report', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(
              data,
              currentPlayer,
            ),
          ),
        );
      }
    });

    socketIoClient.socket.on('buzzer', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => VotePage(
              data,
              currentPlayer,
            ),
          ),
        );
      }
    });

    socketIoClient.socket.on('deathPlayer', (data) {
      socketIoClient.socket.emit(
          'stopTask', {'task': widget.task, 'player': widget.currentPlayer});

      updateCurrentPlayer(data['isAlive'], data['isDeadReport']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (BuildContext context) => TaskPage(
            data['game'],
            currentPlayer,
            blur,
          ),
        ),
      );
    });

    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": currentPlayer},
    );

    startTimer();
  }

  updateCurrentPlayer(isAlive, isDeadReport) async {
    // final SharedPreferences prefs = await _prefs;
    // final current = prefs.getString("currentPlayer");
    // if (current != null) {
    //   final currentDecoded = json.decode(current);
    if (mounted) {
      setState(() {
        currentPlayer['isAlive'] = isAlive;
        currentPlayer['isDeadReport'] = isDeadReport;
      });
    }

    // prefs.setString("currentPlayer", json.encode(currentDecoded));
    // }
  }

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) {
        print("LEFT TIMER === $_start ");
        if (_start == 0) {
          print("timer qr code done");

          socketIoClient.socket.emit("timerTaskDone", {
            "macPlayer": currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => TaskPage(
                  game,
                  currentPlayer,
                  blur,
                ),
              ),
            );
          }

          socketIoClient.socket.emit('stopTask', {
            'task': widget.task,
            'player': currentPlayer,
          });

          timer.cancel();
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }
}
