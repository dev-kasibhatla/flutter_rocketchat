part of flutter_rocketchat;

class _UrlProvider {
  static String _baseUrl = '';
  static String _websocketUrl = '';

  static void initConfig({required String server, required String websocketUrl}) {
    _baseUrl = server;
    _websocketUrl = websocketUrl;
  }

  //user
  static Uri login = Uri.parse('$_baseUrl/api/v1/login');
  static Uri me = Uri.parse('$_baseUrl/api/v1/me');
  static Uri logout = Uri.parse('$_baseUrl/api/v1/logout');
  static Uri userList = Uri.parse('$_baseUrl/api/v1/users.list');

  //channel
  static Uri channelList = Uri.parse('$_baseUrl/api/v1/channels.list');
  static Uri channelHistory = Uri.parse('$_baseUrl/api/v1/channels.history');
  static Uri channelMessages = Uri.parse('$_baseUrl/api/v1/channels.messages');
  static Uri onlineChannelUsers = Uri.parse('$_baseUrl/api/v1/channels.online');
  static Uri channelInfo = Uri.parse('$_baseUrl/api/v1/channels.info');
  static Uri allChannelUsers = Uri.parse('$_baseUrl/api/v1/channels.members');

  //chat
  static Uri chatPostMessage = Uri.parse('$_baseUrl/api/v1/chat.postMessage');
  static Uri chatSendMessage = Uri.parse('$_baseUrl/api/v1/chat.sendMessage'); //https://developer.rocket.chat/reference/api/rest-api/endpoints/messaging/chat-endpoints/send-message
  static Uri getPinnedMessages = Uri.parse('$_baseUrl/api/v1/chat.getPinnedMessages');
  static Uri syncMessages = Uri.parse('$_baseUrl/api/v1/chat.syncMessages');
  static Uri chatDeleteMessage = Uri.parse('$_baseUrl/api/v1/chat.delete');
  static Uri chatReportMessage = Uri.parse('$_baseUrl/api/v1/chat.reportMessage');
}