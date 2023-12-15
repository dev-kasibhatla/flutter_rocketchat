library flutter_rocketchat;

import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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

class RocketChatProvider {

  static Future<void> initConfig({required String server, required String websocketUrl}) async {
    assert (server.isNotEmpty);
    assert (websocketUrl.isNotEmpty);
    _UrlProvider.initConfig(server: server, websocketUrl: websocketUrl);
    await _Requests.init();
    await _StorageProvider.init();
    await _UserDataStore.init();
  }

  static void setOptions({LogType minimumLogLevel = LogType.warning,}) {
    _consoleLogLevel = minimumLogLevel;
    _storeLogLevel = minimumLogLevel;
  }

  static Future<RocketProfile> loginWithUsernamePassword(String username, String password) async {
    assert (username.isNotEmpty);
    assert (password.isNotEmpty);
    return await _Auth.loginWithUserAndPassword(username, password);
  }

  static Future<RocketProfile> fetchProfile() async {
    return await _Auth.fetchProfile();
  }

  static Future<RocketProfile> loginUsingResumeToken(String token) async {
    assert (token.isNotEmpty);
    return await _Auth.loginUsingResumeToken(token);
  }

  static Future<void> logout() async {
    await _Auth.logout();
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
}