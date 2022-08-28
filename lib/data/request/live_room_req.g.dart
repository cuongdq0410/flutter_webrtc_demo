// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_room_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaveRoomReq _$LeaveRoomReqFromJson(Map<String, dynamic> json) => LeaveRoomReq(
      type: json['type'] as String? ?? 'leaveRoom',
      roomID: json['roomID'] as String,
      socketID: json['socketID'] as String,
    );

Map<String, dynamic> _$LeaveRoomReqToJson(LeaveRoomReq instance) =>
    <String, dynamic>{
      'type': instance.type,
      'roomID': instance.roomID,
      'socketID': instance.socketID,
    };
