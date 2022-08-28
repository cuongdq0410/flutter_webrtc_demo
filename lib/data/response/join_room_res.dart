import 'package:json_annotation/json_annotation.dart';

part 'join_room_res.g.dart';

@JsonSerializable()
class JoinRoomRes {
  final String? type;
  final String? message;

  const JoinRoomRes({
    required this.type,
    required this.message,
  });

  factory JoinRoomRes.fromJson(Map<String, dynamic> json) =>
      _$JoinRoomResFromJson(json);

  Map<String, dynamic> toJson() => _$JoinRoomResToJson(this);
}
