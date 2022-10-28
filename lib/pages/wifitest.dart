import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:wifi_hunter/wifi_hunter.dart';
import 'package:wifi_hunter/wifi_hunter_result.dart';

class WifiTest extends StatefulWidget {
  const WifiTest({Key? key}) : super(key: key);

  @override
  State<WifiTest> createState() => WifiTestState();
}

class WifiTestState extends State<WifiTest> {
  WiFiHunterResult wiFiHunterResult = WiFiHunterResult();
  Color huntButtonColor = Colors.lightBlue;

  Future<void> huntWiFis() async {
    try {
      print('wifi hunt');
      final wiFiHunterResults = (await WiFiHunter.huntWiFiNetworks)!;

      print("NOT EMPTY .?????? ${wiFiHunterResults.results.isNotEmpty} \n");
      var contain = wiFiHunterResults.results.where((element) => element.SSID == "KEYCODE");
      print("KEYCODE == $contain, empty ?? ${contain.isEmpty} \n");
      if (wiFiHunterResults != wiFiHunterResult && wiFiHunterResults.results.isNotEmpty && contain.isNotEmpty) {
        print("\nles results sont différents\n");
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
  void initState() {
    Timer.periodic(Duration(seconds: 2), (Timer t) async {
      print("timer");
      await huntWiFis();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print("RESULT IN BUILD == ${wiFiHunterResult.results}");
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('WiFiHunter example app'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TEST'),
              // Container(
              //   margin: const EdgeInsets.symmetric(vertical: 20.0),
              //   child: ElevatedButton(
              //       style: ButtonStyle(
              //           backgroundColor:
              //               MaterialStateProperty.all<Color>(huntButtonColor)),
              //       onPressed: () => huntWiFis(),
              //       child: const Text('Hunt Networks')),
              // ),
              wiFiHunterResult.results.isNotEmpty
                  ? Container(
                      margin: const EdgeInsets.only(
                          bottom: 20.0, left: 30.0, right: 30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          wiFiHunterResult.results.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(vertical: 10.0),
                            child:
                                wiFiHunterResult.results[index].SSID == "KEYCODE"
                                    ?
                                ListTile(
                              leading: Text(distanceToWifi(
                                          wiFiHunterResult.results[index].level)
                                      .toStringAsFixed(1) +
                                  ' m'),
                              title: Text(wiFiHunterResult.results[index].SSID),
                              subtitle: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('BSSID : ' +
                                      wiFiHunterResult.results[index].BSSID),
                                  Text('Capabilities : ' +
                                      wiFiHunterResult
                                          .results[index].capabilities),
                                  Text('Frequency : ' +
                                      wiFiHunterResult.results[index].frequency
                                          .toString()),
                                  Text('Channel Width : ' +
                                      wiFiHunterResult
                                          .results[index].channelWidth
                                          .toString()),
                                  Text('Timestamp : ' +
                                      wiFiHunterResult.results[index].timestamp
                                          .toString())
                                ],
                              ),
                            )
                            : Container(),
                          ),
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}

num distanceToWifi(int rssi) {
  int rssiToOneMetter = -44;
  double environmentalFactor = 2.3;
  double ratio = (rssiToOneMetter - rssi) / (10 * environmentalFactor);

  return pow(10, ratio);
}
