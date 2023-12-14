part of flutter_rocketchat;

class ChannelDetails {
  final String id;
  final String createTimeString;
  final String name;
  final int messagesCount;
  final int usersCount;
  final String lastMessageTimeString;
  final String lastMessage;
  final String createdByUname;
  
  ChannelDetails({
    required this.id,
    required this.createTimeString,
    required this.name,
    required this.messagesCount,
    required this.usersCount,
    required this.lastMessageTimeString,
    required this.lastMessage,
    required this.createdByUname,
  });
  
  factory ChannelDetails.fromJson(Map<String, dynamic> json) {
    return ChannelDetails(
      id: json['_id'],
      createTimeString: json['ts'],
      name: json['name'],
      messagesCount: json['msgs'],
      usersCount: json['usersCount'],
      lastMessageTimeString: json['lastMessage']['ts'],
      lastMessage: json['lastMessage']['msg'],
      createdByUname: json['u']['username'],
    );
  }
  
  @override
  String toString() {
    return jsonEncode(toMap());
  } 
  
  Map toMap() {
    return {
      'id': id,
      'name': name,
      'messageCount': messagesCount,
      'usersCount': usersCount,
      'lastMessage': {
        'ts': lastMessageTimeString,
        'msg': lastMessage,
      },
      'created': {
        'username': createdByUname,
        'createdTimeString': createTimeString,
      },
    };
  }
}