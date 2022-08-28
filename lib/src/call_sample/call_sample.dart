import 'package:flutter/material.dart';
import 'package:flutter_webrtc_demo/data/repository/app_repo.dart';
import 'package:flutter_webrtc_demo/data/request/join_room_request.dart';
import 'package:flutter_webrtc_demo/data/request/live_room_req.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';
import 'signaling.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class CallSample extends StatefulWidget {
  static String tag = 'call_sample';
  final String roomId;
  final Signaling signaling;

  CallSample({
    required this.roomId,
    required this.signaling,
  });

  @override
  _CallSampleState createState() => _CallSampleState();
}

class _CallSampleState extends State<CallSample> {
  List<String> _peerIds = [];
  String? _selfId;
  RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _inCalling = false;
  Session? _session;

  late SharedPreferences _prefs;

  bool _waitAccept = false;

  // ignore: unused_element
  _CallSampleState();

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    _prefs = await SharedPreferences.getInstance();
    _selfId = _prefs.getString('socketId');
    joinRoom();
    widget.signaling.onRoomMessage = (JoinRoomState joinRoomState) {
      switch (joinRoomState) {
        case JoinRoomState.created:
          break;
        case JoinRoomState.alreadyJoined:
          break;
        case JoinRoomState.full:
          _showAlertDialog(context, 'Room is full');
          break;
        case JoinRoomState.joined:
          break;
        default:
      }
    };
    widget.signaling.onSignalingStateChange = (SignalingState state) {
      switch (state) {
        case SignalingState.ConnectionClosed:
        case SignalingState.ConnectionError:
        case SignalingState.ConnectionOpen:
          break;
      }
    };

    widget.signaling.onCallStateChange =
        (Session session, CallState state) async {
      switch (state) {
        case CallState.CallStateNew:
          setState(() {
            _session = session;
          });
          break;
        case CallState.CallStateRinging:
          bool? accept = await _showAcceptDialog();
          if (accept!) {
            _accept();
            setState(() {
              _inCalling = true;
            });
          } else {
            _reject();
          }
          break;
        case CallState.CallStateBye:
          if (_waitAccept) {
            print('peer reject');
            _waitAccept = false;
            Navigator.of(context).pop(false);
          }
          setState(() {
            _localRenderer.srcObject = null;
            _remoteRenderer.srcObject = null;
            _inCalling = false;
            _session = null;
          });
          break;
        case CallState.CallStateInvite:
          _waitAccept = true;
          _showInviteDialog();
          break;
        case CallState.CallStateConnected:
          if (_waitAccept) {
            _waitAccept = false;
            Navigator.of(context).pop(false);
          }
          setState(() {
            _inCalling = true;
          });

          break;
        case CallState.CallStateRinging:
      }
    };

    widget.signaling.onPeersUpdate = ((event) {
      setState(() {
        _selfId = event['self'];
      });
    });

    widget.signaling.onLocalStream = ((stream) {
      _localRenderer.srcObject = stream;
      setState(() {});
    });

    widget.signaling.onAddRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });

    widget.signaling.onRemoveRemoteStream = ((_, stream) {
      _remoteRenderer.srcObject = null;
    });
    widget.signaling.onUpdatePeer = (peerId) {
      if (!_peerIds.contains(peerId)) {
        _peerIds.add(peerId);
        setState(() {});
      }
    };
    widget.signaling.onRemovePeer = (peerId) {
      if (_peerIds.contains(peerId)) {
        _peerIds.remove(peerId);
        setState(() {});
      }
    };
  }

  Future<bool?> _showAcceptDialog() {
    return showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Accept Call?"),
          actions: <Widget>[
            TextButton(
              child: Text("Reject"),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text("Accept"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showInviteDialog() {
    return showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Calling"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
                _hangUp();
              },
            ),
          ],
        );
      },
    );
  }

  _invitePeer(BuildContext context, String peerId, bool useScreen) async {
    if (_selfId != null) {
      widget.signaling
          .invite(peerId, _selfId!, 'video', useScreen, widget.roomId);
    }
  }

  _accept() {
    if (_session != null && _selfId != null) {
      widget.signaling.accept(_session!.sid, _selfId!, widget.roomId);
    }
  }

  _reject() {
    if (_session != null) {
      widget.signaling.reject(_session!.sid);
    }
  }

  _hangUp() {
    if (_session != null) {
      widget.signaling.hangup(_session!.sid);
    }
  }

  _switchCamera() {
    widget.signaling.switchCamera();
  }

  _muteMic() {
    widget.signaling.muteMic();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('P2P Call Sample'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: null,
            tooltip: 'setup',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _inCalling
          ? SizedBox(
              width: 200.0,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    FloatingActionButton(
                      child: const Icon(Icons.switch_camera),
                      onPressed: _switchCamera,
                    ),
                    FloatingActionButton(
                      onPressed: _hangUp,
                      tooltip: 'Hangup',
                      child: Icon(Icons.call_end),
                      backgroundColor: Colors.pink,
                    ),
                    FloatingActionButton(
                      child: const Icon(Icons.mic_off),
                      onPressed: _muteMic,
                    )
                  ]))
          : null,
      body: _inCalling
          ? OrientationBuilder(
              builder: (context, orientation) {
                return Container(
                  child: Stack(children: <Widget>[
                    Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: RTCVideoView(_remoteRenderer),
                          decoration: BoxDecoration(color: Colors.black54),
                        )),
                    Positioned(
                      left: 20.0,
                      top: 20.0,
                      child: Container(
                        width:
                            orientation == Orientation.portrait ? 90.0 : 120.0,
                        height:
                            orientation == Orientation.portrait ? 120.0 : 90.0,
                        child: RTCVideoView(_localRenderer, mirror: true),
                        decoration: BoxDecoration(color: Colors.black54),
                      ),
                    ),
                  ]),
                );
              },
            )
          : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: _peerIds.isNotEmpty ? _peerIds.length : 0,
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(child: Text('Peer ${_peerIds[i]}')),
                      IconButton(
                        onPressed: () {
                          _invitePeer(context, _peerIds[i], false);
                        },
                        icon: Icon(Icons.call),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  joinRoom() async {
    if (_selfId != null) {
      AppRepo.joinRoom(
        JoinRoomReq(
          type: 'joinRoom',
          roomType: 'p2p',
          roomID: widget.roomId,
          socketID: _selfId!,
        ),
      );
    }
  }

  leaveRoom() async {
    if (_selfId != null) {
      AppRepo.leaveRoom(
        LeaveRoomReq(
          roomID: widget.roomId,
          socketID: _selfId!,
        ),
      );
    }
  }

  _showAlertDialog(context, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(content),
          actions: [
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.pop(context);
              },
            )
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    leaveRoom();
    super.dispose();
  }
}
