part of flutter_rocketchat;

class MessageDetails {
  //{messages: [{_id: vc3ZQp7gtqpB9jJsb, rid: GENERAL, msg: Hey kid, ts: 2023-12-14T12:35:56.127Z, u: {_id: k2mdK8H4Btfrk8Hec, username: metakasi, name: metakasi}, _updatedAt: 2023-12-14T12:35:56.275Z, urls: [], mentions: [], channels: [], md: [{type: PARAGRAPH, value: [{type: PLAIN_TEXT, value: Hey kid}]}]}], count: 1, offset: 0, total: 3007, success: true}]

  final String id;
  final String channelId;
  final String message;
  final String createTimeString;
  final String senderId;
  final String rawJson;
  final int createTimeStamp ;

  MessageDetails({
    required this.id,
    required this.channelId,
    required this.message,
    required this.createTimeString,
    required this.senderId,
    required String name,
    required String username,
    required this.rawJson,
    required this.createTimeStamp,
  }) {
    _UserDataStore.addUserToStore(id, username, name, '');
    //"2023-12-18T14:55:42.028Z"
    //convert to int timestamp
    // if(createTimeString.isNotEmpty) {
    //   createTimeStamp = DateTime.parse(createTimeString).millisecondsSinceEpoch~/1000;
    // }
  }

  factory MessageDetails.fromJson(Map<String, dynamic> json) {
    _logd('creating message details from ${jsonEncode(json)}');

    int timestamp = DateTime.parse(json['ts']??'').millisecondsSinceEpoch~/1000;
    // _logd('timestamp: $timestamp from ${json['ts']}');
    //add a profile
    return MessageDetails(
      id: json['_id']??'',
      channelId: json['rid']??'',
      message: json['msg']??'',
      createTimeString: json['ts']??'',
      createTimeStamp: timestamp,
      senderId: json['u']['_id']??'',
      name: json['u']['name']??'',
      username: json['u']['username']??'',
      rawJson: jsonEncode(json),
    );
  }

  factory MessageDetails.fromStreamJson(Map<dynamic, dynamic> json) {
    //{msg: changed, collection: stream-room-messages, id: id, fields: {eventName: 657c4ed42995977855b545e8, args: [{_id: T8oaqddLnH7Nvhase, rid: 657c4ed42995977855b545e8, msg: ola, ts: {$date: 1702893070207}, u: {_id: iYoGcEJj4gvM5zdRC, username: coolboi, name: coolboi}, _updatedAt: {$date: 1702893070643}, urls: [], mentions: [], channels: [], md: [{type: PARAGRAPH, value: [{type: PLAIN_TEXT, value: ola}]}]}]}}
    _logd('creating message details from stream ${jsonEncode(json)}');
    return MessageDetails(
      channelId: json['fields']?['args']?[0]?['rid']??'',
      id: json['fields']?['args']?[0]?['_id']??'',
      message: json['fields']?['args']?[0]?['msg']??'',
      createTimeString: '',
      createTimeStamp: (json['fields']?['args']?[0]?['ts']?['\$date']??''),
      senderId: json['fields']?['args']?[0]?['u']?['_id']??'',
      name: json['fields']?['args']?[0]?['u']?['name']??'',
      username: json['fields']?['args']?[0]?['u']?['username']??'',
      rawJson: jsonEncode(json),
    );
  }

  factory MessageDetails.createEmpty () {
    return MessageDetails(
      channelId: '',
      id: '',
      username: 'Unknown',
      message: 'Error fetching this message',
      createTimeString: (DateTime.now().millisecondsSinceEpoch~/1000).toString(),
      name: 'Unknown',
      rawJson: '{}',
      senderId: 'Unknown',
      createTimeStamp: DateTime.now().millisecondsSinceEpoch~/1000,
    );

  }

  RocketProfile getProfile() {
    return _UserDataStore._profiles[id]??RocketProfile.createErrorProfile(errorMessage: 'no profile found for $id');
  }

  /// returns a human readable time string like 8:40pm, 12:30am, 1:00pm
  /// - [agoSecondsThreshold] is the number of seconds until the time is displayed as 'x minutes ago' or 'x hours ago'
  /// - if [agoSecondsThreshold] is 0, then the time will always be displayed as a human readable time string
  /// - if [agoSecondsThreshold] is -1, time will be displayed as date and time
  /// - Maximum limit for [agoSecondsThreshold] is 60*60*23 (23 hours)
  /// - Current device time is used to calculate the time difference
  String getHumanReadableTimeString({int agoSecondsThreshold = 0}) {
    if (agoSecondsThreshold < -1) {
      agoSecondsThreshold = -1;
    }
    if (agoSecondsThreshold > 82800) {
      agoSecondsThreshold = 82800;
    }
    int now = DateTime.now().millisecondsSinceEpoch~/1000;
    int diff = now - createTimeStamp;
    if (agoSecondsThreshold == 0 || diff > agoSecondsThreshold) {
      //return human readable time
      return DateFormat.jm().format(DateTime.fromMillisecondsSinceEpoch(createTimeStamp*1000));
    } else if (agoSecondsThreshold == -1) {
      //return date and time
      return DateFormat('MMM d, y, h:mm a').format(DateTime.fromMillisecondsSinceEpoch(createTimeStamp*1000));
    } else {
      // if less than 60 seconds ago, return 'just now'
      if (diff < 60) {
        return 'just now';
      }
      // if less than 60 minutes ago, return 'x minutes ago'
      if (diff < 3600) {
        return '${(diff/60).floor()} minutes ago';
      }
      // if less than 24 hours ago, return 'x hours ago'
      if (diff < 86400) {
        return '${(diff/3600).floor()} hours ago';
      }
      // if more than 24 hours ago, return 'x days ago'
      return '${(diff/86400).floor()} days ago';
    }
  }

  Map toMap() {
    return {
      'id': id,
      'channelId': channelId,
      'message': message,
      'createTimeString': createTimeString,
      'createTimeStamp': createTimeStamp,
      'sender': {
        'id': senderId,
      },
      'rawJson': rawJson,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}