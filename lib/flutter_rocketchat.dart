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
  /// Call this before using any other methods in this package.
  /// - [server] is the server url to connect to
  /// - [websocketUrl] is the websocket url to connect to. Typically $serverUrl/websocket
  static Future<void> initConfig(
      {required String server, required String websocketUrl}) async {
    assert(server.isNotEmpty);
    assert(websocketUrl.isNotEmpty);
    _UrlProvider.initConfig(server: server, websocketUrl: websocketUrl);
    await _Requests.init();
    await _StorageProvider.init();
    await _UserDataStore.init();
  }

  /// Returns true if the realtime api is connected, false otherwise.
  ///
  /// **This does not mean that the user is authenticated.**
  static bool realtimeConnected() {
    return _SocketHelper.connectionEstablished;
  }

  /// Initiates a connection to the rocket chat's realtime api.
  ///
  /// - Requires the initConfig to be set correctly before calling this method.
  /// - [onConnected] is called when the connection is established with
  /// Rocket chat realtime api.
  /// You should ideally do your authentication and next steps here.
  ///
  /// - [onDisconnected] is called when the connection is closed
  /// with Rocket chat realtime api.
  /// You should ideally add your reconnection logic here.
  /// This also means that authentication is lost (if any).
  static Future<void> initRealtimeApiConnection(
      {Function? onConnected, Function? onDisconnected}) async {
    await _SocketHelper.init(
        onConnectionClosed: onDisconnected,
        onConnectionEstablished: onConnected);
  }

  /// Closes the connection to the realtime api.
  /// Ideally call this when the user logs out, onDispose, etc.
  ///
  /// Leaving the connection open will result in unnecessary
  /// battery drain, network usage, etc.
  static Future<void> closeRealtimeApiConnection() async {
    await _SocketHelper.closeConnection();
  }

  /// Lets you set additional custom options for the package.
  /// - [minimumLogLevel] is the minimum log level to be logged to console
  /// Use this to reduce the amount of logs printed to console.
  /// Defaults to [LogType.warning]. This is a good level to see relevant errors and warnings.
  static void setOptions({
    LogType minimumLogLevel = LogType.warning,
  }) {
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
  static Future<RocketProfile> loginWithUsernamePassword(
      String username, String password) async {
    assert(username.isNotEmpty);
    assert(password.isNotEmpty);
    return await _Auth.loginWithUserAndPassword(username, password);
  }

  /// - Fetches the user's profile data
  /// - Returns a [RocketProfile] object with the user's profile data
  /// - If the fetch fails, the [RocketProfile] object will have an error message
  /// - If the fetch is successful, the [RocketProfile] object will have the user's profile data.
  /// The [authToken] and [userId] will **not** be set in the [RocketProfile] object.
  ///
  /// **Important**
  ///
  /// Ideally, you should use [loginWithUsernamePassword] or [loginUsingResumeToken]
  /// to set the [authToken] and [userId] values. They also contain the profile data
  /// returned by this method.
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
    assert(token.isNotEmpty);
    return await _Auth.loginUsingResumeToken(token);
  }

  /// - Authenticates the realtime api connection with the resume token
  /// - [token] is the resume token to login with
  /// - [onSuccess] is called when the connection is established. It returns the [authToken], [tokenExpiry] and [userId]
  /// - [onError] is called when an error occurs. It returns a [Map] with the error response
  ///
  /// **Important**
  /// - Authentication is only valid until the realtime api connection is closed
  /// or the token expires.
  /// - You should only call this method when the realtime api connection is established.
  /// If you call this method before the connection is established, it will fail
  /// and throw an exception.
  /// - You should call this method only once per realtime api connection.
  ///
  /// Additional notes:
  /// - This method will set the [authToken] and [userId] values
  /// - It is up to the developer using this package to store the [authToken] and
  /// [userId] values for future use.
  /// - The developer may also choose to store the [authToken] and [userId]
  /// in a secure storage to persist across sessions for a better UX.
  /// - The resume token is a token that is returned by the server when the user logs in.
  /// - Validity of the resume token depends on the server configuration.
  /// - If you don't have a resume token, you can get one by logging in with username and password
  /// Even REST API login will return a resume token that can be used here.
  static void loginRealtimeUsingResumeToken(String token,
      {Function(String authToken, int expiry, String userId)? onSuccess,
      Function(Map errorResponse)? onError}) {
    return _Auth.authenticateRealtimeWithResumeToken(token,
        onConnected: onSuccess, onError: onError);
  }


  /// - Requires the user to be authenticated using REST API
  /// Only the fields that need to be updated should be passed.
  /// Passing all fields empty will result in a thrown exception.
  /// - [name] is the name to update
  /// - [email] is the email to update
  /// - [username] is the username to update
  /// - [bio] is the bio to update
  /// - [statusType] is the status type to update
  /// - [statusText] is the status text to update
  /// - [nickname] is the nickname to update
  /// - Returns true if the update was successful, false otherwise
  ///
  /// Rocket chat docs: [https://developer.rocket.chat/reference/api/rest-api/endpoints/user-management/users-endpoints/update-own-basic-information]()
  static Future<bool> updateUserBasicInfo({
    String name = '',
    String email = '',
    String username = '',
    String bio = '',
    String statusType = '',
    String statusText = '',
    String nickname = '',
  }) async {
    return await _Auth.updateProfile(
        name: name,
        email: email,
        username: username,
        bio: bio,
        statusType: statusType,
        statusText: statusText,
        nickname: nickname);
  }

  /// - Requires the user to be authenticated using REST API
  /// - [avatarUrl] is the avatar url to update
  /// - Returns true if the update was successful, false otherwise
  ///
  /// Rocket chat docs: [https://developer.rocket.chat/reference/api/rest-api/endpoints/user-management/users-endpoints/set-user-avatar]()
  static Future<bool> updateSelfAvatar({required String avatarUrl}) async {
    return await _Auth.updateSelfAvatar(avatarUrl);
  }

  /// - Returns true if logout was successful, false otherwise
  /// - Additional notes:
  /// - This method will clear the [authToken] and [userId] values
  /// - It is up to the developer using this package to clear the [authToken] and
  /// [userId] values from storage upon successful logout
  static Future<bool> logout() async {
    return await _Auth.logout();
  }

  /// - Returns true if the user is authenticated, false otherwise
  /// - This is only true for REST API authentication
  /// - Use [isRealtimeAuthenticated] to check if the user is authenticated using realtime api
  static bool isAuthenticated() {
    return _Auth.isAuthenticated();
  }

  /// - Returns true if the user is authenticated, false otherwise
  /// - This is only true for realtime api authentication
  /// - This is only true if the realtime api connection is also established
  /// - Use [isAuthenticated] to check if the user is authenticated using REST API
  static bool isRealtimeAuthenticated() {
    return _Auth._realtimeApiAuthenticated;
  }

  /// - Requires the user to be authenticated using REST API
  /// - [channel] is the channel id to fetch messages for
  /// - [offset] is the offset to fetch messages from (pagination)
  /// - [count] is the number of messages to fetch (pagination)
  /// - [sort] is the sort order of the messages
  /// - Returns a list of [MessageDetails] objects
  /// - If the fetch fails, the list will be empty
  static Future<List<MessageDetails>> getChannelMessages(
      String channel, int offset, int count, Map<String, dynamic> sort) async {
    return await _RocketMessageStore.getChannelMessages(
        channel: channel, offset: offset, count: count, sort: sort);
  }

  /// - Requires the user to be authenticated using REST API
  /// - Returns a list of [ChannelDetails] objects of all the channels
  /// visible to the authenticated user
  static Future<List<ChannelDetails>> listAvailableChannels() async {
    return await _RocketMessageStore.listAvailableChannels();
  }

  /// - Requires the user to be authenticated using REST API
  /// - [channelId] is the channel id to fetch auth data from
  /// - [status] is to filter the users by status. Providing an invalid status will return an empty list
  /// By default it is empty and will return all users
  /// - [count] is the number of users to fetch. Default is 500
  ///
  /// Additional details:
  /// For a particular channel, fetches and caches (on disk) the details of all the users in a channel
  ///
  /// This will save io time when fetching and processing messages. You should ideally do this for large channels
  /// with a lot of users and messages to improve runtime performance.
  ///
  /// This data stays cached across sessions.
  static Future precacheUsersFromChannel(
      {required String channelId,
      List<String> status = const [],
      int count = 500}) {
    return _UserDataStore.precacheUsersFromChannel(
        channelId: channelId, status: status, count: count);
  }

  /// - Requires the user to be authenticated using REST API
  /// - [message] is the message content to send
  /// - [channelId] is the channel id to send the message to
  /// - Returns true if the message was sent successfully, false otherwise
  static Future<bool> sendMessage(
      {required String message, required String channelId}) async {
    return await _RocketMessageStore.sendMessage(
        message: message, channelId: channelId);
  }

  /// - Requires the user to be authenticated using REST API
  /// - [messageId] is the message id to report
  /// - [description] is the reason for reporting the message
  /// - Returns true if the message was reported successfully, false otherwise
  static Future<bool> reportMessage(
      {required String messageId, required String description}) async {
    return await _RocketMessageStore.reportMessage(
        messageId: messageId, description: description);
  }

  /// - Requires the user to be authenticated using REST API
  /// - [messageId] is the message id to delete
  /// - [channelId] is the channel id to delete the message from
  /// - Returns true if the message was deleted successfully, false otherwise
  static Future<bool> deleteMessage(
      {required String messageId, required String channelId}) async {
    return await _RocketMessageStore.deleteMessage(
        messageId: messageId, channelId: channelId);
  }

  /// - Requires the user to be authenticated using REST API
  /// - [channelId] is the channel id to fetch pinned messages from
  /// - [offset] is the offset to fetch messages from (pagination)
  /// - [count] is the number of messages to fetch (pagination)
  /// - Returns a list of [MessageDetails] objects of all the pinned messages
  /// in the channel (depending on the offset and count)
  /// - If the fetch fails, the list will be empty
  static Future<List<MessageDetails>> getPinnedMessages(
      {required String channelId, int offset = 0, int count = 0}) async {
    return await _RocketMessageStore.getPinnedMessages(
        channelId: channelId, offset: offset, count: count);
  }

  /// Fetches messages from the server for the given channel by streaming from the realtime api
  ///
  /// Requires the user to be authenticated using realtime api
  ///
  /// - [channelId] is the channel id to fetch messages for
  /// - [latestMessageTimestamp] is the timestamp of the latest message in the channel to fetch until
  /// - [count] is the number of messages to fetch
  /// - [lastMessageFetchedTimestamp] is the timestamp of the last message fetched
  /// - [onResult] is the callback to be called when messages are fetched. It returns a list of [MessageDetails]
  /// - [onError] is the callback to be called when an error occurs. It returns a [Map] with the error response
  static void getChannelMessageHistoryRealtimeApi(
      {required String channelId,
      required int latestMessageTimestamp,
      required int count,
      required int lastMessageFetchedTimestamp,
      Function(List<MessageDetails> messages)? onResult,
      Function(Map errorResponse)? onError}) {
    _RocketMessageStore.streamMessageHistoryFromRealtimeApi(
        channelId, latestMessageTimestamp, count, lastMessageFetchedTimestamp,
        onResponse: onResult, onError: onError);
  }

  /// Fetches messages from the server for the given channel by streaming from the realtime api
  ///
  /// Requires the user to be authenticated using realtime api
  ///
  /// - [channelId] is the channel id to fetch messages for
  /// - [onReady] is called when the stream is ready to receive messages
  /// - [onMessage] is called when a message is received. It returns a [MessageDetails] object
  /// - [onError] is called when an error occurs. It returns a [Map] with the error response
  static void listenToChannelMessages(
      {required String channelId,
      Function(MessageDetails)? onMessage,
      Function(Map error)? onError,
      Function()? onReady}) {
    _RocketMessageStore.startListeningToChannelMessages(channelId,
        onMessage: onMessage, onError: onError, onReady: onReady);
  }

  /// Unsubscribes from all message streams subscribed to in the current
  /// realtime api connection session
  static void unListenToAllMessageStreams() {
    _RocketMessageStore.unSubAllChannelMessages();
  }
}
