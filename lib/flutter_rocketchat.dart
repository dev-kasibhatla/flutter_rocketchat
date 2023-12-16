library flutter_rocketchat;

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

part 'data/auth.dart';
part 'data/message_store.dart';
part 'data/profile.dart';
part 'helpers/requests.dart';
part 'helpers/url_provider.dart';
part 'helpers/log.dart';
part 'helpers/durations.dart';
part 'data/single_channel.dart';
part 'data/single_message.dart';
part 'data/user_data_store.dart';
part 'helpers/storage.dart';
part 'helpers/sockets.dart';

class RocketChatProvider {

  static Future<void> initConfig({required String server, required String websocketUrl}) async {
    assert (server.isNotEmpty);
    assert (websocketUrl.isNotEmpty);
    _UrlProvider.initConfig(server: server, websocketUrl: websocketUrl);
    await _Requests.init();
    await _StorageProvider.init();
    await _UserDataStore.init();
  }

  static bool connected() {
    return _SocketHelper.connectionEstablished;
  }

  static Future<void> initRealtimeApiConnection({Function? onConnected, Function? onDisconnected}) async {
    await _SocketHelper.init(onConnectionClosed: onDisconnected, onConnectionEstablished: onConnected);
  }

  static Future<void> closeRealtimeApiConnection() async {
    await _SocketHelper.closeConnection();
  }

  static void setOptions({LogType minimumLogLevel = LogType.warning,}) {
    _consoleLogLevel = minimumLogLevel;
    _storeLogLevel = minimumLogLevel;
  }

  /// - Login with username and password
  ///
  /// - [username] is the username to login with
  ///
  /// - [password] is the password to login with
  ///
  /// - Returns a [RocketProfile] object with the user's profile data
  ///
  /// - If the login fails, the [RocketProfile] object will have an error message
  ///
  /// - If the login is successful, the [RocketProfile] object will have the user's profile data.
  /// Additionally, the [authToken] and [userId] will be set.
  /// This is the only way to set these values apart from [loginUsingResumeToken]
  ///
  /// Additional notes:
  /// - It is up to the developer using this package to store the [authToken] and
  /// [userId] for future use.
  ///
  /// - The developer may also choose to store the [authToken] and [userId]
  /// in a secure storage to persist across sessions for a better UX.
  static Future<RocketProfile> loginWithUsernamePassword(String username, String password) async {
    assert (username.isNotEmpty);
    assert (password.isNotEmpty);
    return await _Auth.loginWithUserAndPassword(username, password);
  }

  static Future<RocketProfile> fetchProfile() async {
    return await _Auth.fetchProfile();
  }

  /// - Login with resume token
  ///
  /// - [token] is the resume token to login with
  ///
  /// - Returns a [RocketProfile] object with the user's profile data
  ///
  /// - If the login fails, the [RocketProfile] object will have an error message
  ///
  /// - If the login is successful, the [RocketProfile] object will have the user's profile data.
  ///
  /// Additional notes:
  /// - It is up to the developer using this package to store the [authToken] and
  /// [userId] for future use.
  ///
  /// - The developer may also choose to store the [authToken] and [userId]
  /// in a secure storage to persist across sessions for a better UX.
  ///
  /// - The resume token is a token that is returned by the server when the user logs in.
  ///
  /// - Validity of the resume token depends on the server configuration.
  ///
  /// - If you don't have a resume token, you can get one by logging in with username and password
  static Future<RocketProfile> loginUsingResumeToken(String token) async {
    assert (token.isNotEmpty);
    return await _Auth.loginUsingResumeToken(token);
  }

  static void loginRealtimeUsingResumeToken(String token, {Function(String authToken, int expiry, String userId)? onSuccess, Function(Map errorResponse)? onError}) {
    return _Auth.authenticateRealtimeWithResumeToken(token, onConnected: onSuccess, onError: onError);
  }

  /// - Returns true if logout was successful, false otherwise
  /// - Additional notes:
  /// - This method will clear the [authToken] and [userId] values
  /// - It is up to the developer using this package to clear the [authToken] and
  /// [userId] values from storage upon successful logout
  static Future<bool> logout() async {
    return await _Auth.logout();
  }

  static bool isAuthenticated() {
    return _Auth.isAuthenticated();
  }

  //channel
  static Future<List> getChannelMessages(String channel, int offset, int count, Map<String, dynamic> sort) async {
    return await _RocketMessageStore.getChannelMessages(channel: channel, offset: offset, count: count, sort: sort);
  }

  static Future<List<ChannelDetails>> listAvailableChannels () async {
    return await _RocketMessageStore.listAvailableChannels();
  }

  static Future precacheUsersFromChannel({required String channelId, List<String> status = const [], int count = 500}) {
    return _UserDataStore.precacheUsersFromChannel(channelId: channelId, status: status, count: count);
  }

  //messages
  static Future<bool> sendMessage({required String message, required String channelId}) async {
    return await _RocketMessageStore.sendMessage(message: message, channelId: channelId);
  }

  static Future<bool> reportMessage({required String messageId, required String description}) async {
    return await _RocketMessageStore.reportMessage(messageId: messageId, description: description);
  }

  static Future<bool> deleteMessage({required String messageId, required String channelId}) async {
    return await _RocketMessageStore.deleteMessage(messageId: messageId, channelId: channelId);
  }

  static Future<List<MessageDetails>> getPinnedMessages ({required String channelId, int offset=0, int count=0}) async {
    return await _RocketMessageStore.getPinnedMessages(channelId: channelId, offset: offset, count: count);
  }

}