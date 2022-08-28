import 'dart:convert';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_demo/data/repository/app_repo.dart';
import 'package:flutter_webrtc_demo/data/request/ice_candidate.dart';
import 'package:flutter_webrtc_demo/data/request/ice_candidate_req.dart';
import 'package:flutter_webrtc_demo/data/request/offer_req.dart';
import 'package:flutter_webrtc_demo/data/request/rtc_session_description.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'random_string.dart';

import '../utils/device_info.dart'
    if (dart.library.js) '../utils/device_info_web.dart';
import '../utils/websocket.dart'
    if (dart.library.js) '../utils/websocket_web.dart';
import '../utils/turn.dart' if (dart.library.js) '../utils/turn_web.dart';

enum SignalingState {
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

enum JoinRoomState {
  created,
  alreadyJoined,
  joined,
  full,
}

enum CallState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
}

class Session {
  Session({required this.sid, required this.pid});

  String pid;
  String sid;
  RTCPeerConnection? pc;
  RTCDataChannel? dc;
  List<RTCIceCandidate> remoteCandidates = [];
}

class Signaling {
  Signaling();

  JsonEncoder _encoder = JsonEncoder();
  JsonDecoder _decoder = JsonDecoder();
  SharedPreferences? _prefs;
  String? socketId;
  SimpleWebSocket? _socket;
  Map<String, Session> _sessions = {};
  MediaStream? _localStream;
  List<MediaStream> _remoteStreams = <MediaStream>[];

  Function(SignalingState state)? onSignalingStateChange;
  Function(Session session, CallState state)? onCallStateChange;
  Function(MediaStream stream)? onLocalStream;
  Function(Session session, MediaStream stream)? onAddRemoteStream;
  Function(Session session, MediaStream stream)? onRemoveRemoteStream;
  Function(dynamic event)? onPeersUpdate;
  Function(Session session, RTCDataChannel dc, RTCDataChannelMessage data)?
      onDataChannelMessage;
  Function(Session session, RTCDataChannel dc)? onDataChannel;
  Function(JoinRoomState roomMessage)? onRoomMessage;
  Function(String peerId)? onUpdatePeer;
  Function(String peerId)? onRemovePeer;

  String get sdpSemantics =>
      WebRTC.platformIsWindows ? 'plan-b' : 'unified-plan';

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      {
        'urls': 'turn:210.211.101.105:3478',
        'username': '3gtel',
        'pass': '3g123456',
        'credential': '3g123456'
      }
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {
      "OfferToReceiveAudio": true,
      "OfferToReceiveVideo": true,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };

  final Map<String, dynamic> _dcConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> connect() async {
    _socket = SimpleWebSocket('wss://wss.boffice.vn/VnetManager/wsvnetjs');

    _socket?.onOpen = () {
      print('onOpen');
      send('sent', {"action": "connectDone", "host": "flutter_app_rtc"});
      onSignalingStateChange?.call(SignalingState.ConnectionOpen);
    };

    _socket?.onMessage = (message) {
      print('Received data: ' + message);
      onMessage(_decoder.convert(message));
    };

    _socket?.onClose = (int? code, String? reason) {
      print('Closed by server [$code => $reason]!');
      onSignalingStateChange?.call(SignalingState.ConnectionClosed);
    };

    await _socket?.connect();
  }

  void switchCamera() {
    if (_localStream != null) {
      Helper.switchCamera(_localStream!.getVideoTracks()[0]);
    }
  }

  void muteMic() {
    if (_localStream != null) {
      bool enabled = _localStream!.getAudioTracks()[0].enabled;
      _localStream!.getAudioTracks()[0].enabled = !enabled;
    }
  }

  void invite(
    String peerId,
    String selfId,
    String media,
    bool useScreen,
    String roomId,
  ) async {
    var sessionId = selfId + '-' + peerId;
    Session session = await _createSession(
      null,
      peerId: peerId,
      sessionId: sessionId,
      media: media,
      screenSharing: useScreen,
      selfId: selfId,
    );
    _sessions[sessionId] = session;
    if (media == 'data') {
      _createDataChannel(session);
    }
    _createOffer(
      session,
      media,
      roomId,
      selfId,
      sessionId: sessionId,
    );
    onCallStateChange?.call(session, CallState.CallStateNew);
    onCallStateChange?.call(session, CallState.CallStateInvite);
  }

  void bye(String sessionId) {
    var sess = _sessions[sessionId];
    if (sess != null) {
      _closeSession(sess);
    }
  }

  void accept(String sessionId, String selfId, String roomId) {
    var session = _sessions[sessionId];
    if (session == null) {
      return;
    }
    _createAnswer(session, 'video', roomId, selfId, sessionId);
  }

  void reject(String sessionId) {
    var session = _sessions[sessionId];
    if (session == null) {
      return;
    }
    bye(session.sid);
  }

  void onMessage(message) async {
    Map<String, dynamic> mapData = message;
    var data = mapData['data'];
    print('=========MESSAGE TYPE: ${mapData['type']} ==============');
    switch (mapData['type']) {
      case 'leaveRoom':
        {
          var peerId = data as String;
          _closeSessionByPeerId(peerId);
        }
        break;
      case 'bye':
        {
          var sessionId = data['session_id'];
          print('bye: ' + sessionId);
          var session = _sessions.remove(sessionId);
          if (session != null) {
            onCallStateChange?.call(session, CallState.CallStateBye);
            _closeSession(session);
          }
        }
        break;
      case 'keepalive':
        {
          print('keepalive response!');
        }
        break;
      case 'roomMessage':
        String? roomMessage = mapData['message'];
        print('======roomMessage====');
        if (onRoomMessage != null && roomMessage != null) {
          switch (roomMessage) {
            case 'created':
              onRoomMessage?.call(JoinRoomState.created);
              break;
            case 'alreadyJoined':
              onRoomMessage?.call(JoinRoomState.alreadyJoined);
              break;
            case 'joined':
              onRoomMessage?.call(JoinRoomState.joined);
              break;
            case 'full':
              onRoomMessage?.call(JoinRoomState.full);
              break;
            default:
          }
        }
        break;
      case 'notification':
        Map<String, dynamic>? message = mapData['message'];
        print(message);
        if (message != null) {
          switch (message['type']) {
            case 'addPeer':
              String? peerId = message['config']['peerID'];
              bool? shouldCreateOffer = message['shouldCreateOffer'] ?? false;
              if (peerId != null) {
                onUpdatePeer?.call(peerId);
              }
              break;
            case 'removePeer':
              String? peerId = message['config']['peerID'];
              if (peerId != null) {
                onRemovePeer?.call(peerId);
              }
              break;
            default:
          }
        }
        break;

      /// On this when having offer
      case 'relay':
        Map<String, dynamic>? message = mapData['message'];

        if (message != null) {
          String? type = message['type'];
          switch (type) {
            case 'sessionDescription':
              String? peerId = message['config']['peerID'];

              /// Sdp của người gửi
              final sessionDescriptionMap =
                  message['config']['sessionDescription'];
              if (sessionDescriptionMap != null) {
                RTCSessionDescriptionReq sessionDescription =
                    RTCSessionDescriptionReq.fromJson(sessionDescriptionMap);
                switch (sessionDescription.type) {
                  case 'offer':
                    var media = 'video';
                    SharedPreferences _prefs =
                        await SharedPreferences.getInstance();
                    String selfId = _prefs.getString('socketId') ?? '';
                    String sessionId = sessionDescription.sessionId ?? '';
                    var session = _sessions[sessionId];
                    var newSession = await _createSession(
                      session,
                      peerId: peerId ?? '',
                      sessionId: sessionId,
                      media: media,
                      screenSharing: false,
                      selfId: selfId,
                    );
                    _sessions[sessionId] = newSession;
                    await newSession.pc?.setRemoteDescription(
                      RTCSessionDescription(
                          sessionDescription.sdp, sessionDescription.type),
                    );
                    // await _createAnswer(
                    //   newSession,
                    //   media,
                    //   sessionDescription.roomId ?? '',
                    //   selfId,
                    // );

                    if (newSession.remoteCandidates.length > 0) {
                      newSession.remoteCandidates.forEach((candidate) async {
                        await newSession.pc?.addCandidate(candidate);
                      });
                      newSession.remoteCandidates.clear();
                    }
                    onCallStateChange?.call(newSession, CallState.CallStateNew);

                    onCallStateChange?.call(
                        newSession, CallState.CallStateRinging);
                    break;
                  case 'answer':
                    String sessionId = sessionDescription.sessionId ?? '';
                    var session = _sessions[sessionId];
                    session?.pc?.setRemoteDescription(
                      RTCSessionDescription(
                          sessionDescription.sdp, sessionDescription.type),
                    );
                    onCallStateChange?.call(
                        session!, CallState.CallStateConnected);
                    break;
                  default:
                }
              }
              break;
            case 'iceCandidate':
              String? peerId = message['config']['peerID'];

              /// iceCandidate người gửi gửi đi
              final iceCandidateMap = message['config']['iceCandidate'];
              if (iceCandidateMap != null) {
                IceCandidate iceCandidate =
                    IceCandidate.fromJson(iceCandidateMap);
                String? sessionId = iceCandidate.sessionId ?? '';
                var session = _sessions[sessionId];
                RTCIceCandidate candidate = RTCIceCandidate(
                  iceCandidate.candidate,
                  iceCandidate.sdpMid,
                  iceCandidate.sdpMLineIndex,
                );

                if (session != null) {
                  if (session.pc != null) {
                    await session.pc?.addCandidate(candidate);
                  } else {
                    session.remoteCandidates.add(candidate);
                  }
                } else {
                  _sessions[sessionId] =
                      Session(pid: peerId ?? '', sid: sessionId)
                        ..remoteCandidates.add(candidate);
                }
              }
              break;
            default:
          }
        }
        break;
      default:
        break;
    }
    switch (mapData['mesage']) {
      case 'Done':
        socketId = mapData['socketID'];
        print('socketId ${mapData['socketID']}');
        _prefs = await SharedPreferences.getInstance();
        _prefs?.setString('socketId', socketId ?? '');
        break;
      default:
        break;
    }
  }

  Future<MediaStream> createStream(String media, bool userScreen) async {

    final Map<String, dynamic> mediaConstraints = {
      'audio': userScreen ? false : true,
      'video': userScreen
          ? true
          : {
              'mandatory': {
                'minWidth':
                    '640', // Provide your own width, height and frame rate here
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
    };

    MediaStream stream = userScreen
        ? await navigator.mediaDevices.getDisplayMedia(mediaConstraints)
        : await navigator.mediaDevices.getUserMedia(mediaConstraints);
    onLocalStream?.call(stream);
    return stream;
  }

  Future<Session> _createSession(
    Session? session, {
    required String peerId,
    required String selfId,
    required String sessionId,
    required String media,
    required bool screenSharing,
  }) async {
    var newSession = session ?? Session(sid: sessionId, pid: peerId);
    if (media != 'data')
      _localStream = await createStream(media, screenSharing);
    print(_iceServers);
    RTCPeerConnection pc = await createPeerConnection(
      {
        ..._iceServers,
        ...{'sdpSemantics': sdpSemantics}
      },
      _config,
    );
    if (media != 'data') {
      switch (sdpSemantics) {
        case 'plan-b':
          pc.onAddStream = (MediaStream stream) {
            onAddRemoteStream?.call(newSession, stream);
            _remoteStreams.add(stream);
          };
          await pc.addStream(_localStream!);
          break;
        case 'unified-plan':
          // Unified-Plan
          pc.onTrack = (event) {
            if (event.track.kind == 'video') {
              onAddRemoteStream?.call(newSession, event.streams[0]);
            }
          };
          _localStream!.getTracks().forEach((track) {
            pc.addTrack(track, _localStream!);
          });
          break;
      }

      // Unified-Plan: Simuclast
      /*
      await pc.addTransceiver(
        track: _localStream.getAudioTracks()[0],
        init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendOnly, streams: [_localStream]),
      );

      await pc.addTransceiver(
        track: _localStream.getVideoTracks()[0],
        init: RTCRtpTransceiverInit(
            direction: TransceiverDirection.SendOnly,
            streams: [
              _localStream
            ],
            sendEncodings: [
              RTCRtpEncoding(rid: 'f', active: true),
              RTCRtpEncoding(
                rid: 'h',
                active: true,
                scaleResolutionDownBy: 2.0,
                maxBitrate: 150000,
              ),
              RTCRtpEncoding(
                rid: 'q',
                active: true,
                scaleResolutionDownBy: 4.0,
                maxBitrate: 100000,
              ),
            ]),
      );*/
      /*
        var sender = pc.getSenders().find(s => s.track.kind == "video");
        var parameters = sender.getParameters();
        if(!parameters)
          parameters = {};
        parameters.encodings = [
          { rid: "h", active: true, maxBitrate: 900000 },
          { rid: "m", active: true, maxBitrate: 300000, scaleResolutionDownBy: 2 },
          { rid: "l", active: true, maxBitrate: 100000, scaleResolutionDownBy: 4 }
        ];
        sender.setParameters(parameters);
      */
    }
    pc.onIceCandidate = (candidate) async {
      if (candidate == null) {
        print('onIceCandidate: complete!');
        return;
      }
      // This delay is needed to allow enough time to try an ICE candidate
      // before skipping to the next one. 1 second is just an heuristic value
      // and should be thoroughly tested in your own environment.
      await Future.delayed(
        const Duration(seconds: 1),
        () => AppRepo.onIceCandidate(
          IceCandidateReq(
            srcID: selfId,
            desID: peerId,
            iceCandidate: IceCandidate(
              candidate: candidate.candidate,
              sdpMLineIndex: candidate.sdpMLineIndex,
              sdpMid: candidate.sdpMid,
              sessionId: sessionId,
            ),
          ),
        ),
      );
    };

    pc.onIceConnectionState = (state) {};

    pc.onRemoveStream = (stream) {
      onRemoveRemoteStream?.call(newSession, stream);
      _remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    pc.onDataChannel = (channel) {
      _addDataChannel(newSession, channel);
    };

    newSession.pc = pc;
    return newSession;
  }

  void _addDataChannel(Session session, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      onDataChannelMessage?.call(session, channel, data);
    };
    session.dc = channel;
    onDataChannel?.call(session, channel);
  }

  Future<void> _createDataChannel(Session session,
      {label: 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = RTCDataChannelInit()
      ..maxRetransmits = 30;
    RTCDataChannel channel =
        await session.pc!.createDataChannel(label, dataChannelDict);
    _addDataChannel(session, channel);
  }

  Future<void> _createOffer(
      Session session, String media, String roomId, String selfId,
      {required String sessionId}) async {
    try {
      RTCSessionDescription s =
          await session.pc!.createOffer({'offerToReceiveVideo': 1});
      await session.pc!.setLocalDescription(s);
      await AppRepo.createOffer(
        OfferReq(
          srcID: selfId,
          desID: session.pid,
          sessionDescription: RTCSessionDescriptionReq(
            sdp: s.sdp,
            type: s.type,
            sessionId: sessionId,
          ),
          roomID: roomId,
        ),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _createAnswer(
    Session session,
    String media,
    String roomId,
    String selfId,
    String sessionId,
  ) async {
    try {
      print('======== create answer ========');
      RTCSessionDescription s =
          await session.pc!.createAnswer(media == 'data' ? _dcConstraints : {});
      await session.pc!.setLocalDescription(s);
      await AppRepo.createOffer(
        OfferReq(
          srcID: selfId,
          desID: session.pid,
          sessionDescription: RTCSessionDescriptionReq(
            sdp: s.sdp,
            type: s.type,
            roomId: roomId,
            sessionId: sessionId,
          ),
          roomID: roomId,
        ),
      );
    } catch (e) {
      print(e.toString());
    }
  }

  send(event, data) {
    _socket?.send(_encoder.convert(data));
  }

  Future<void> _cleanSessions() async {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((element) async {
        await element.stop();
      });
      await _localStream!.dispose();
      _localStream = null;
    }
    _sessions.forEach((key, sess) async {
      await sess.pc?.close();
      await sess.dc?.close();
    });
    _sessions.clear();
  }

  void _closeSessionByPeerId(String peerId) {
    var session;
    _sessions.removeWhere((String key, Session sess) {
      var ids = key.split('-');
      session = sess;
      return peerId == ids[0] || peerId == ids[1];
    });
    if (session != null) {
      _closeSession(session);
      onCallStateChange?.call(session, CallState.CallStateBye);
    }
  }

  Future<void> _closeSession(Session session) async {
    _localStream?.getTracks().forEach((element) async {
      await element.stop();
    });
    await _localStream?.dispose();
    _localStream = null;

    await session.pc?.close();
    await session.dc?.close();
  }

  hangup(String sessionId) {
    print('bye: ' + sessionId);
    var session = _sessions.remove(sessionId);
    if (session != null) {
      onCallStateChange?.call(session, CallState.CallStateBye);
      _closeSession(session);
    }
  }

  close() async {
    await _cleanSessions();
    _socket?.close();
  }
}
