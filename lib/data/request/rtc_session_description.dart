import 'package:json_annotation/json_annotation.dart';

part 'rtc_session_description.g.dart';

@JsonSerializable()
class RTCSessionDescriptionReq {
  RTCSessionDescriptionReq({this.sdp, this.type, this.sessionId, this.roomId});

  String? sdp;
  String? type;
  String? sessionId;
  String? roomId;

  factory RTCSessionDescriptionReq.fromJson(Map<String, dynamic> json) =>
      _$RTCSessionDescriptionReqFromJson(json);

  Map<String, dynamic> toJson() => _$RTCSessionDescriptionReqToJson(this);
}
