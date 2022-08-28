// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rtc_session_description.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RTCSessionDescriptionReq _$RTCSessionDescriptionReqFromJson(
        Map<String, dynamic> json) =>
    RTCSessionDescriptionReq(
      sdp: json['sdp'] as String?,
      type: json['type'] as String?,
      sessionId: json['sessionId'] as String?,
      roomId: json['roomId'] as String?,
    );

Map<String, dynamic> _$RTCSessionDescriptionReqToJson(
        RTCSessionDescriptionReq instance) =>
    <String, dynamic>{
      'sdp': instance.sdp,
      'type': instance.type,
      'sessionId': instance.sessionId,
      'roomId': instance.roomId,
    };
