import 'package:json_annotation/json_annotation.dart';

part 'join_room_request.g.dart';

@JsonSerializable()
class JoinRoomReq {
  final String type;
  final String roomType;
  final String roomID;
  final String socketID;

  const JoinRoomReq({
    required this.type,
    required this.roomType,
    required this.roomID,
    required this.socketID,
  });

  factory JoinRoomReq.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomReqFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomReqToJson(this);
}
