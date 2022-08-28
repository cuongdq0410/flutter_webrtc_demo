// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_room_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JoinRoomReq _$JoinRoomReqFromJson(Map<String, dynamic> json) => JoinRoomReq(
      type: json['type'] as String,
      roomType: json['roomType'] as String,
      roomID: json['roomID'] as String,
      socketID: json['socketID'] as String,
    );

Map<String, dynamic> _$JoinRoomReqToJson(JoinRoomReq instance) =>
    <String, dynamic>{
      'type': instance.type,
      'roomType': instance.roomType,
      'roomID': instance.roomID,
      'socketID': instance.socketID,
    };
