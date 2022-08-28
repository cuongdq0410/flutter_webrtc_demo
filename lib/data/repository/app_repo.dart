import 'package:flutter_webrtc_demo/data/app_api.dart';
import 'package:flutter_webrtc_demo/data/injection.dart';
import 'package:flutter_webrtc_demo/data/request/ice_candidate_req.dart';
import 'package:flutter_webrtc_demo/data/request/join_room_request.dart';
import 'package:flutter_webrtc_demo/data/request/live_room_req.dart';
import 'package:flutter_webrtc_demo/data/request/offer_req.dart';

import '../response/join_room_res.dart';

class AppRepo {
  static final AppApi appApi = getIt<AppApi>();

  static Future joinRoom(JoinRoomReq joinRoomReq) async {
    return appApi.joinRoom(joinRoomReq);
  }

  static Future leaveRoom(LeaveRoomReq joinRoomReq) async {
    return appApi.leaveRoom(joinRoomReq);
  }

  static Future createOffer(OfferReq offerReq) async {
    return appApi.createOffer(offerReq);
  }

  static Future onIceCandidate(IceCandidateReq iceCandidateReq) async {
    return appApi.postIceCandidate(iceCandidateReq);
  }
}
