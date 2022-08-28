import 'package:json_annotation/json_annotation.dart';

import 'rtc_session_description.dart';

part 'offer_req.g.dart';

@JsonSerializable(explicitToJson: true)
class OfferReq {
  final String? type;
  final String? relayType;
  final String srcID;
  final String desID;
  final String roomID;
  final RTCSessionDescriptionReq? sessionDescription;

  const OfferReq({
    this.type = 'relay',
    this.relayType = 'sessionDescription',
    required this.srcID,
    required this.desID,
    required this.sessionDescription,
    required this.roomID,
  });

  factory OfferReq.fromJson(Map<String, dynamic> json) =>
      _$OfferReqFromJson(json);

  Map<String, dynamic> toJson() => _$OfferReqToJson(this);
}
