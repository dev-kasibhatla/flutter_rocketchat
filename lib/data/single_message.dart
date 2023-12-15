part of flutter_rocketchat;

class MessageDetails {
  //{messages: [{_id: vc3ZQp7gtqpB9jJsb, rid: GENERAL, msg: Hey kid, ts: 2023-12-14T12:35:56.127Z, u: {_id: k2mdK8H4Btfrk8Hec, username: metakasi, name: metakasi}, _updatedAt: 2023-12-14T12:35:56.275Z, urls: [], mentions: [], channels: [], md: [{type: PARAGRAPH, value: [{type: PLAIN_TEXT, value: Hey kid}]}]}], count: 1, offset: 0, total: 3007, success: true}]

  final String id;
  final String channelId;
  final String message;
  final String createTimeString;
  final String senderId;

  MessageDetails({
    required this.id,
    required this.channelId,
    required this.message,
    required this.createTimeString,
    required this.senderId,
    required String name,
    required String username,
  }) {
    _UserDataStore.addUserToStore(id, username, name, '');
  }

  factory MessageDetails.fromJson(Map<String, dynamic> json) {
    _logd('creating message details from ${jsonEncode(json)}');
    //add a profile
    return MessageDetails(
      id: json['_id']??'',
      channelId: json['rid']??'',
      message: json['msg']??'',
      createTimeString: json['ts']??'',
      senderId: json['u']['_id']??'',
      name: json['u']['name']??'',
      username: json['u']['username']??'',
    );
  }

  RocketProfile getProfile() {
    return _UserDataStore._profiles[id]??RocketProfile.createErrorProfile(errorMessage: 'no profile found for $id');
  }

  Map toMap() {
    return {
      'id': id,
      'channelId': channelId,
      'message': message,
      'createTimeString': createTimeString,
      'sender': {
        'id': senderId,
      },
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}