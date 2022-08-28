// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ice_candidate.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IceCandidate _$IceCandidateFromJson(Map<String, dynamic> json) => IceCandidate(
      sdpMLineIndex: json['sdpMLineIndex'] as int?,
      candidate: json['candidate'] as String?,
    );

Map<String, dynamic> _$IceCandidateToJson(IceCandidate instance) =>
    <String, dynamic>{
      'sdpMLineIndex': instance.sdpMLineIndex,
      'candidate': instance.candidate,
    };
