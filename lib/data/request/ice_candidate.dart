import 'package:json_annotation/json_annotation.dart';

part 'ice_candidate.g.dart';

@JsonSerializable(explicitToJson: true)
class IceCandidate {
  final int? sdpMLineIndex;
  final String? candidate;
  final String? sdpMid;
  final String? sessionId;

  const IceCandidate({
    this.sdpMLineIndex,
    this.candidate,
    this.sdpMid,
    this.sessionId,
  });

  factory IceCandidate.fromJson(Map<String, dynamic> json) =>
      _$IceCandidateFromJson(json);

  Map<String, dynamic> toJson() => _$IceCandidateToJson(this);
}
