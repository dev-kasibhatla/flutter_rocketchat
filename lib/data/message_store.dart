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

  static void startListeningToChannelMessages(String channelId) {
    _logd('startListeningToChannelMessages: $channelId');
  }


}