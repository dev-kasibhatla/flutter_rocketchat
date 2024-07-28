import 'package:flutter_rocketchat/flutter_rocketchat.dart';

class RocketData {
  final String host = "";
  String uname = "";
  String password = "";
  String channel = "";
  late final RocketChatProvider rocketChatProvider;
  RocketData() {
    rocketChatProvider = RocketChatProvider();
  }
}