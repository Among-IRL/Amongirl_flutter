import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiHunter extends StatefulWidget {
  const WifiHunter({Key? key}) : super(key: key);

  @override
  State<WifiHunter> createState() => WifiHunterState();
}

class WifiHunterState extends State<WifiHunter> {
  List<WiFiAccessPoint> accessPoints = <WiFiAccessPoint>[];
  StreamSubscription<List<WiFiAccessPoint>>? subscription;

  bool get isStreaming => subscription != null;
  Timer? timer;

  @override
  void initState() {
    _startScan();
    _getScannedResults();
    _startListeningToScanResults();
    timer = Timer.periodic(
        Duration(seconds: 2), (Timer t) {
          print("timer");
          final getScan = _getScannedResults();
          final startListenning = _startListeningToScanResults();

          print("get scan : $getScan");
          print("start listenning : $startListenning");
        });
    super.initState();
  }

  Future<void> _startScan() async {
    // check if can-startScan
    final can = await WiFiScan.instance.canStartScan();
    // if can-not, then show error
    if (can != CanStartScan.yes) {
      if (mounted) print("Cannot start scan: $can");
      return;
    }

    // call startScan API
    final result = await WiFiScan.instance.startScan();
    if (mounted) print("startScan: $result");
    // reset access points.
    setState(() => accessPoints = <WiFiAccessPoint>[]);
  }

  Future<bool> _canGetScannedResults() async {
    // check if can-getScannedResults
    final can = await WiFiScan.instance.canGetScannedResults();
    // if can-not, then show error
    if (can != CanGetScannedResults.yes) {
      if (mounted) print("Cannot get scanned results: $can");
      accessPoints = <WiFiAccessPoint>[];
      return false;
    }
    return true;
  }

  Future<void> _getScannedResults() async {
    print(_canGetScannedResults());
    if (await _canGetScannedResults()) {
      // get scanned results
      final results = await WiFiScan.instance.getScannedResults();
      setState(() => accessPoints = results);
    }
  }

  Future<void> _startListeningToScanResults() async {
    if (await _canGetScannedResults()) {
      subscription = WiFiScan.instance.onScannedResultsAvailable
          .listen((result) => setState(() => accessPoints = result));
    }
  }

  void _stopListeningToScanResults() {
    subscription?.cancel();
    setState(() => subscription = null);
  }

  @override
  void dispose() {
    super.dispose();
    // stop subscription for scanned results
    _stopListeningToScanResults();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Center(
                    child: accessPoints.isEmpty
                        ? const Text("NO SCANNED RESULTS")
                        : ListView.builder(
                            itemCount: accessPoints.length,
                            itemBuilder: (context, i) {
                              if(accessPoints[i].ssid == "KEYCODE") {
                                return _AccessPointTile(
                                    accessPoint: accessPoints[i]);
                              }
                              else{
                                return Container();
                              }
                            }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Show tile for AccessPoint.
///
/// Can see details when tapped.
class _AccessPointTile extends StatelessWidget {
  final WiFiAccessPoint accessPoint;

  const _AccessPointTile({Key? key, required this.accessPoint})
      : super(key: key);

  // build row that can display info, based on label: value pair.
  Widget _buildInfo(String label, dynamic value) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey)),
        ),
        child: Row(
          children: [
            Text(
              "$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(child: Text(value.toString()))
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final title = accessPoint.ssid.isNotEmpty ? accessPoint.ssid : "**EMPTY**";
    final signalIcon = accessPoint.level >= -80
        ? Icons.signal_wifi_4_bar
        : Icons.signal_wifi_0_bar;
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(signalIcon),
      title: Text(title),
      subtitle:
          Text(distanceToWifi(accessPoint.level).toStringAsFixed(1) + "m"),
    );
  }
}

num distanceToWifi(int rssi) {
  int rssiToOneMetter = -44;
  double environmentalFactor = 2.3;
  double ratio = (rssiToOneMetter - rssi) / (10 * environmentalFactor);

  return pow(10, ratio);
}
