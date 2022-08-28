// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_req.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfferReq _$OfferReqFromJson(Map<String, dynamic> json) => OfferReq(
      type: json['type'] as String? ?? 'relay',
      relayType: json['relayType'] as String? ?? 'sessionDescription',
      srcID: json['srcID'] as String,
      desID: json['desID'] as String,
      sessionDescription: json['sessionDescription'] == null
          ? null
          : RTCSessionDescriptionReq.fromJson(
              json['sessionDescription'] as Map<String, dynamic>),
      roomID: json['roomID'] as String,
    );

Map<String, dynamic> _$OfferReqToJson(OfferReq instance) => <String, dynamic>{
      'type': instance.type,
      'relayType': instance.relayType,
      'srcID': instance.srcID,
      'desID': instance.desID,
      'roomID': instance.roomID,
      'sessionDescription': instance.sessionDescription?.toJson(),
    };
