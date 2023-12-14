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

}