// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ice_candidate_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IceCandidateReq _$IceCandidateReqFromJson(Map<String, dynamic> json) =>
    IceCandidateReq(
      type: json['type'] as String? ?? 'relay',
      relayType: json['relayType'] as String? ?? 'sessionDescription',
      srcID: json['srcID'] as String,
      desID: json['desID'] as String,
      iceCandidate:
          IceCandidate.fromJson(json['iceCandidate'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$IceCandidateReqToJson(IceCandidateReq instance) =>
    <String, dynamic>{
      'type': instance.type,
      'relayType': instance.relayType,
      'srcID': instance.srcID,
      'desID': instance.desID,
      'iceCandidate': instance.iceCandidate,
    };
