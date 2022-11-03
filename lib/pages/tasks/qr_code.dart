import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:amoungirl/services/socket_io_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../task_page.dart';

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

  Map<String, dynamic> game = {};

  String message = "";

  late Timer _timer;
  int _start = 10;

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
          )
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
              "player": widget.currentPlayer,
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
          game = data;
        });
      }
    });

    socketIoClient.socket.on('taskNotComplete', (data) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => TaskPage(data['game']),
          ),
        );
      }
    });

    socketIoClient.socket.on('deathPlayer', (data){
      if(data['mac'] == widget.currentPlayer['mac']) {
        socketIoClient.socket.emit('stopTask', {
          'task': widget.task,
          'player': widget.currentPlayer
        });
      }
    });

    socketIoClient.socket.emit(
      "startTask",
      {'task': widget.task, "player": widget.currentPlayer},
    );

    startTimer();
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
            "macPlayer": widget.currentPlayer["mac"],
            "macTask": widget.task["mac"],
            "accomplished": true,
          });

          if (game.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => TaskPage(game),
              ),
            );
          }

          socketIoClient.socket.emit('stopTask', {
            'task': widget.task,
            'player': widget.currentPlayer
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
