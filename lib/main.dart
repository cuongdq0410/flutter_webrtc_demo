import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/data/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/call_sample/call_sample.dart';
import 'src/call_sample/data_channel_sample.dart';
import 'src/call_sample/signaling.dart';
import 'src/route_item.dart';

void main() async {
  await setupInjection();
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class _MyAppState extends State<MyApp> {
  List<RouteItem> items = [];
  String? roomName;
  late SharedPreferences _prefs;

  bool _dataChannel = false;
  late Signaling signaling;
  TextEditingController roomIdController = TextEditingController();

  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
  }

  _initData() async {
    signaling = Signaling()..connect();
    _prefs = await SharedPreferences.getInstance();
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Flutter-WebRTC'),
        ),
        body: ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(0.0),
          itemCount: items.length,
          itemBuilder: (context, i) {
            return _buildRow(context, items[i]);
          },
        ),
      ),
    );
  }

  void showDemoDialog<T>(
      {required BuildContext context, required Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T? value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => _dataChannel
                  ? DataChannelSample()
                  : CallSample(
                      roomId: roomIdController.text,
                      signaling: signaling,
                    ),
            ),
          );
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
      context: context,
      child: AlertDialog(
        title: const Text('Input your room'),
        content: TextField(
          controller: roomIdController,
          decoration: InputDecoration(
            hintText: 'Input your room',
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.pop(context, DialogDemoAction.cancel);
            },
          ),
          ElevatedButton(
            child: const Text('Connect'),
            onPressed: () {
              Navigator.pop(context, DialogDemoAction.connect);
            },
          )
        ],
      ),
    );
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
        title: 'P2P Call',
        subtitle: 'P2P Call',
        push: (BuildContext context) {
          _dataChannel = false;
          _showAddressDialog(context);
        },
      ),
    ];
  }

  @override
  void dispose() {
    roomIdController.dispose();
    super.dispose();
  }
}
