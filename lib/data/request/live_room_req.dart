import 'package:json_annotation/json_annotation.dart';

part 'live_room_req.g.dart';

@JsonSerializable()
class LeaveRoomReq {
  final String? type;
  final String roomID;
  final String socketID;

  const LeaveRoomReq({
    this.type = 'leaveRoom',
    required this.roomID,
    required this.socketID,
  });

  factory LeaveRoomReq.fromJson(Map<String, dynamic> json) =>
      _$LeaveRoomReqFromJson(json);

  Map<String, dynamic> toJson() => _$LeaveRoomReqToJson(this);
}
