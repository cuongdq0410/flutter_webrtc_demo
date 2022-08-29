import 'package:json_annotation/json_annotation.dart';

import 'ice_candidate.dart';

part 'ice_candidate_req.g.dart';

@JsonSerializable()
class IceCandidateReq {
  final String? type;
  final String? relayType;
  final String srcID;
  final String desID;
  final String roomID;
  final IceCandidate iceCandidate;

  const IceCandidateReq({
    this.type = 'relay',
    this.relayType = 'ICECandidate',
    required this.srcID,
    required this.desID,
    required this.iceCandidate,
    required this.roomID,
  });

  factory IceCandidateReq.fromJson(Map<String, dynamic> json) =>
      _$IceCandidateReqFromJson(json);

  Map<String, dynamic> toJson() => _$IceCandidateReqToJson(this);
}
