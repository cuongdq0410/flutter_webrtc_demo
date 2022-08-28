import 'package:dio/dio.dart';
import 'package:flutter_webrtc_demo/data/request/ice_candidate_req.dart';
import 'package:flutter_webrtc_demo/data/request/live_room_req.dart';
import 'package:retrofit/retrofit.dart';

import 'request/join_room_request.dart';
import 'request/offer_req.dart';

part 'app_api.g.dart';

@RestApi()
abstract class AppApi {
  factory AppApi(Dio dio, {String baseUrl}) = _AppApi;

  @POST('')
  Future joinRoom(@Body() JoinRoomReq joinRoomReq);

  @POST('')
  Future leaveRoom(@Body() LeaveRoomReq leaveRoomReq);

  @POST('')
  Future createOffer(@Body() OfferReq offerReq);

  @POST('')
  Future postIceCandidate(@Body() IceCandidateReq iceCandidateReq);
}
