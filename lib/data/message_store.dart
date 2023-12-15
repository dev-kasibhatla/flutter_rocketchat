part of flutter_rocketchat;

class _RocketMessageStore {

  /// Fetches messages from the server from the given channel
  ///
  /// [channel] is the channel id
  ///
  /// [offset] is the number of messages to skip (pagination)
  ///
  /// [count] is the number of messages to fetch (page size)
  static Future<List<MessageDetails>> getChannelMessages ({required String channel, required int offset, required int count, Map sort = const {}}) async {
    try{
      _logd('syncMessages: channel: $channel, offset: $offset, count: $count, sort: $sort');
      String body = "?roomId=$channel&offset=$offset&count=$count&sort=${jsonEncode(sort)}";
      RResponse response = await _Requests.get(_UrlProvider.channelMessages,body );
      _logd('syncMessages: response: ${response.data}');
      List<MessageDetails> messages = [];
      for (var message in response.data['messages']) {
        messages.add(MessageDetails.fromJson(message));
      }
      return messages;
    } catch (e,s) {
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
  static Future<List<ChannelDetails>> listAvailableChannels () async {
    try{
      _logd('starting listAvailableChannels');
      RResponse response = await _Requests.get(_UrlProvider.channelList, '');
      _logd('listAvailableChannels: response: ${response.data}');
      List<ChannelDetails> channels = [];
      for (var channel in response.data['channels']) {
        channels.add(ChannelDetails.fromJson(channel));
      }
      return channels;
    } catch (e,s) {
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
  static Future<bool> sendMessage({required String message, required String channelId}) async {
    assert (message.isNotEmpty);
    assert (channelId.isNotEmpty);
    _logd('sendMessage: $message, $channelId');
    Map<String, dynamic> body = {
      'message' : {
        'rid': channelId,
        'msg': message,
      }
    };
    try {
      RResponse response = await _Requests.post(_UrlProvider.chatSendMessage, body: body);
      _logd('sendMessage: response: ${response.data}');
      return response.success;
    } catch (e,s) {
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
  static Future<bool> reportMessage({required String messageId, required String description}) async {
    assert (messageId.isNotEmpty);
    assert (description.isNotEmpty);
    _logd('reportMessage: $messageId, $description');
    try{
      Map<String, dynamic> body = {
        'messageId': messageId,
        'description': description,
      };
      RResponse response = await _Requests.post(_UrlProvider.chatReportMessage, body: body);
      _logd('reportMessage: response: ${response.data}');
      return response.success;
    } catch (e,s) {
      _loge('reportMessage: $e\n$s');
      return false;
    }
  }

  static Future<bool> deleteMessage({required String channelId, required String messageId}) async {
    assert (channelId.isNotEmpty);
    assert (messageId.isNotEmpty);
    _logd('deleteMessage: $channelId, $messageId');
    try{
      Map<String, dynamic> body = {
        'roomId': channelId,
        'msgId': messageId,
      };
      RResponse response = await _Requests.post(_UrlProvider.chatDeleteMessage, body: body);
      _logd('deleteMessage: response: ${response.data}');
      return response.success;
    } catch (e,s) {
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
  static Future<List<MessageDetails>> getPinnedMessages ({required String channelId, int offset=0, int count=0}) async {
    assert (channelId.isNotEmpty);
    _logd('getPinnedMessages: $channelId');
    try{
      String params = "?roomId=$channelId&offset=$offset";
      if (count > 0) {
        params += '&count=$count';
      }
      RResponse response = await _Requests.get(_UrlProvider.getPinnedMessages, params);
      _logd('getPinnedMessages: response: ${response.data}');
      List<MessageDetails> messages = [];
      if (response.success) {
        for (var message in response.data['messages']) {
          messages.add(MessageDetails.fromJson(message));
        }
      }
      return messages;
    } catch (e,s) {
      _loge('getPinnedMessages: $e\n$s');
      return [];
    }
  }

  static void startListeningToChannelMessages(String channelId) {
    _logd('startListeningToChannelMessages: $channelId');
  }


}