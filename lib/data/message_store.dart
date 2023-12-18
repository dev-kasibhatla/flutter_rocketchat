part of flutter_rocketchat;

class _RocketMessageStore {
  /// Fetches messages from the server from the given channel
  ///
  /// [channel] is the channel id
  ///
  /// [offset] is the number of messages to skip (pagination)
  ///
  /// [count] is the number of messages to fetch (page size)
  static Future<List<MessageDetails>> getChannelMessages(
      {required String channel,
      required int offset,
      required int count,
      Map sort = const {}}) async {
    try {
      _logd(
          'syncMessages: channel: $channel, offset: $offset, count: $count, sort: $sort');
      String body =
          "?roomId=$channel&offset=$offset&count=$count&sort=${jsonEncode(sort)}";
      RResponse response =
          await _Requests.get(_UrlProvider.channelMessages, body);
      _logd('syncMessages: response: ${response.data}');
      List<MessageDetails> messages = [];
      for (var message in response.data['messages']) {
        messages.add(MessageDetails.fromJson(message));
      }
      return messages;
    } catch (e, s) {
      _loge('syncMessages: $e\n$s');
      return [];
    }
  }

  /// Fetches a list of available channels from the server
  ///
  /// returns a list of [ChannelDetails]
  ///
  /// returns an empty list if no channels are found
  ///
  /// returns an empty list if an error occurs
  static Future<List<ChannelDetails>> listAvailableChannels() async {
    try {
      _logd('starting listAvailableChannels');
      RResponse response = await _Requests.get(_UrlProvider.channelList, '');
      _logd('listAvailableChannels: response: ${response.data}');
      List<ChannelDetails> channels = [];
      for (var channel in response.data['channels']) {
        channels.add(ChannelDetails.fromJson(channel));
      }
      return channels;
    } catch (e, s) {
      _loge('listAvailableChannels: $e\n$s');
      return [];
    }
  }

  /// Sends a message to the given channel
  ///
  /// [message] is the message to send
  ///
  /// [channelId] is the channel id to send the message to
  ///
  /// returns true if the message was sent successfully
  ///
  /// returns false if the message failed to send
  static Future<bool> sendMessage(
      {required String message, required String channelId}) async {
    assert(message.isNotEmpty);
    assert(channelId.isNotEmpty);
    _logd('sendMessage: $message, $channelId');
    Map<String, dynamic> body = {
      'message': {
        'rid': channelId,
        'msg': message,
      }
    };
    try {
      RResponse response =
          await _Requests.post(_UrlProvider.chatSendMessage, body: body);
      _logd('sendMessage: response: ${response.data}');
      return response.success;
    } catch (e, s) {
      _loge('sendMessage: $e\n$s');
      return false;
    }
  }

  /// Reports a message to the server
  ///
  /// [messageId] is the id of the message to report
  ///
  /// [description] is the reason for reporting the message
  ///
  /// returns true if the message was reported successfully
  ///
  /// returns false if the message failed to report
  static Future<bool> reportMessage(
      {required String messageId, required String description}) async {
    assert(messageId.isNotEmpty);
    assert(description.isNotEmpty);
    _logd('reportMessage: $messageId, $description');
    try {
      Map<String, dynamic> body = {
        'messageId': messageId,
        'description': description,
      };
      RResponse response =
          await _Requests.post(_UrlProvider.chatReportMessage, body: body);
      _logd('reportMessage: response: ${response.data}');
      return response.success;
    } catch (e, s) {
      _loge('reportMessage: $e\n$s');
      return false;
    }
  }

  static Future<bool> deleteMessage(
      {required String channelId, required String messageId}) async {
    assert(channelId.isNotEmpty);
    assert(messageId.isNotEmpty);
    _logd('deleteMessage: $channelId, $messageId');
    try {
      Map<String, dynamic> body = {
        'roomId': channelId,
        'msgId': messageId,
      };
      RResponse response =
          await _Requests.post(_UrlProvider.chatDeleteMessage, body: body);
      _logd('deleteMessage: response: ${response.data}');
      return response.success;
    } catch (e, s) {
      _loge('deleteMessage: $e\n$s');
      return false;
    }
  }

  /// Fetches pinned messages from the server for the given channel
  ///
  /// [channelId] is the channel id to fetch pinned messages for
  ///
  /// [offset] is the number of messages to skip (pagination)
  ///
  /// [count] is the number of messages to fetch (page size)
  /// if count is 0, all messages will be fetched
  ///
  /// returns a list of [MessageDetails]
  static Future<List<MessageDetails>> getPinnedMessages(
      {required String channelId, int offset = 0, int count = 0}) async {
    assert(channelId.isNotEmpty);
    _logd('getPinnedMessages: $channelId');
    try {
      String params = "?roomId=$channelId&offset=$offset";
      if (count > 0) {
        params += '&count=$count';
      }
      RResponse response =
          await _Requests.get(_UrlProvider.getPinnedMessages, params);
      _logd('getPinnedMessages: response: ${response.data}');
      List<MessageDetails> messages = [];
      if (response.success) {
        for (var message in response.data['messages']) {
          messages.add(MessageDetails.fromJson(message));
        }
      }
      return messages;
    } catch (e, s) {
      _loge('getPinnedMessages: $e\n$s');
      return [];
    }
  }

  static void startListeningToChannelMessages(String channelId, {Function(MessageDetails)? onMessage, Function(Map error)? onError, Function? onReady}) {
    _logd('startListeningToChannelMessages: $channelId');
    if (!_SocketHelper._connected) {
      throw Exception(
          'Realtime API socket not connected. Connect to socket before sending messages');
    }
    try {
      Map<String, dynamic> body = {
        "params": [
          channelId,
          false, //back-compatibility
        ],
        "name": "stream-room-messages",
      };
      String subId = '';
      subId = _SocketHelper.sendMessage(body, 'sub', keepAlive: true, onResponse: (Map response) {
        _logd('startListeningToChannelMessages response: $response');
        if (response['msg'] == 'ready') {
          if (response.containsKey('subs')) {
            _logd('stream subs: ${response['subs']}. Looking for subId: $subId');
            if (response['subs'].contains(subId)) {
              _logd('stream-room-messages subscription successful');
              _SocketHelper.roomMessageSubscriptions[subId] = channelId;
              if (onReady != null) {
                onReady();
              }
            } else {
              _loge('stream-room-messages subscription failed');
              if (onError != null) {
                onError({
                  'error': 'stream-room-messages subscription failed',
                });
              }
            }
          }
        } else if (response['msg'] == 'changed') {
          /// process and return message
          if (onMessage != null) {
            onMessage(MessageDetails.fromStreamJson(response));
          } else {
            _logw('subscribed to channel id $channelId but no onMessage callback provided');
          }
        } else {
          if (onError != null) {
            onError(response);
          }
        }
      }, onError: (Map errorResponse) {
        _loge('startListeningToChannelMessages error: $errorResponse');
        if (onError != null) {
          onError(errorResponse);
        }
      });
    } catch (e, s) {
      _loge('startListeningToChannelMessages: $e\n$s');
      if (onError != null) {
        onError({
          'error': e.toString(),
        });
      }
    }
  }

  static void unSubAllChannelMessages() {
    for (String subID in _SocketHelper.roomMessageSubscriptions.keys) {
      unsubSingleStream(subID);
    }
  }

  //todo: put this in _SocketHelper
  static void unsubSingleStream (String subId) {
    _logd('unsubSingleStream: $subId');
    if (!_SocketHelper._connected) {
      throw Exception(
          'Realtime API socket not connected. Connect to socket before sending messages');
    }
    try {
      _SocketHelper.sendMessage(const {}, 'unsub', precalculatedId: subId, onResponse: (Map response) {
        _logd('unsubSingleStream response: $response');
        if (response['msg'] == 'result') {
          _logd('unsubSingleStream successful');
        } else {
          _loge('unsubSingleStream failed');
        }
      }, onError: (Map errorResponse) {
        _loge('unsubSingleStream error: $errorResponse');
      });
    } catch (e, s) {
      _loge('unsubSingleStream: $e\n$s');
    }
  }

  static void streamMessageHistoryFromRealtimeApi(
      String channelId, int timestamp, int count, int date,
      {Function(List<MessageDetails> messages)? onResponse, Function(Map errorResponse)? onError}) {
    _logd(
        'streamMessageHistoryFromRealtimeApi: $channelId, $timestamp, $count, $date');
    if (!_SocketHelper._connected) {
      throw Exception(
          'Realtime API socket not connected. Connect to socket before sending messages');
    }
    String timestampString = timestamp.toString();
    if (timestamp == 0) {
      timestampString = 'null';
    }
    if (date == 0) {
      //set it to 30 days ago
      date = ((DateTime.now().millisecondsSinceEpoch - 2592000000)~/1000);
    }
    try {
      Map<String, dynamic> body = {
        "params": [
          channelId,
          {
            "\$date": timestampString,
          },
          count,
          {
            "\$date": date
          }
        ],
        "method": "loadHistory",
      };
      _SocketHelper.sendMessage(body, 'method', onResponse: (Map response) {
        _logd('streamMessageHistoryFromRealtimeApi response: $response');
        if (response['msg'] == 'result') {
          List<MessageDetails> messages = [];
          for (var message in response['result']['messages']) {
            messages.add(MessageDetails.fromJson(message));
          }
          if (onResponse != null) {
            onResponse(messages);
          }
        } else {
          if (onError != null) {
            onError(response);
          }
        }
      }, onError: (Map errorResponse) {
        _loge('streamMessageHistoryFromRealtimeApi error: $errorResponse');
        if (onError != null) {
          onError(errorResponse);
        }
      });
    } catch (e, s) {
      _loge('streamMessageHistoryFromRealtimeApi: $e\n$s');
      if (onError != null) {
        onError({
          'error': e.toString(),
        });
      }
    }
  }
}
