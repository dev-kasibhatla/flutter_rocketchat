part of flutter_rocketchat;

enum RocketMessageStatus {
  sent,
  responded,
  failed,
}

enum SubTypes {
  streamRoomMessages,
}

class _SocketHelper {
  static late IOWebSocketChannel _channel;
  static bool _connected = false;
  static bool connectionEstablished = false;
  static String sessionId = '';

  static Future init({Function? onConnectionEstablished, Function? onConnectionClosed}) async {
    assert(_UrlProvider._websocketUrl.isNotEmpty);
    messageStatuses = {};
    messageCallbacks = {};
    messageErrorCallbacks = {};
    keepAliveMessages = [];
    roomMessageSubscriptions = {};
    if(_connected) {
      if (!connectionEstablished) {
        //disconnect and continue with connection
        await closeConnection();
      } else {
        //already connected
        _logw('socket already connected. Not establishing a new connection');
        onConnectionEstablished?.call();
        return;
      }
    }
    try {
      _channel = IOWebSocketChannel.connect(
          Uri.parse(_UrlProvider._websocketUrl),
          connectTimeout: _Durations.socketConnectTimeout);

      await _channel.ready;
      _connected = true;
      waitForConnectionEstablished(onConnectionEstablished: onConnectionEstablished?? () {});
      sendConnectMessage();
      _channel.stream.listen(
          (event) {
            // _logd('socket event: $event');
            try{
              handleMessage(jsonDecode(event));
            } catch (e,s) {
              _loge('socket event error: $e\n$s');
            }
          },
          onError: (e, s) {
            _loge('socket error: $e\n$s');
            _connected = false;
            connectionEstablished = false;
            if (onConnectionClosed != null) {
              onConnectionClosed();
            }
          },
          cancelOnError: true,
          onDone: () {
            _logd('socket closed');
            _connected = false;
            connectionEstablished = false;
            if (onConnectionClosed != null) {
              onConnectionClosed();
            }
          });
    } catch (e, s) {
      _loge('socket init error: $e\n$s');
    }
  }

  static void waitForConnectionEstablished ({required Function onConnectionEstablished}) async {
    int retries = 20;
    for (int i = 0; i < retries; i++) {
      if (connectionEstablished) {
        onConnectionEstablished();
        break;
      }
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  static void handleMessage(Map message) {
    _logd('handleMessage: $message type: ${message.runtimeType}');
    //{msg: connected, session: DS5txy92fjmTCBwbs}
    switch (message['msg']??'') {
      case 'connected':
        _logd('socket connected');
        sessionId = message['session']??'';
        connectionEstablished = true;
        break;
      case 'ping':
        handlePingMessages();
        break;
      case 'error':
        _logw('socket error: ${message['error']}');
        if (message.containsKey('offendingMessage')) {
          String id = message['offendingMessage']['id']??'';
          if (messageStatuses.containsKey(id)) {
            messageStatuses[id] = RocketMessageStatus.failed;
            messageErrorCallbacks[id]!(message);
          }
          //remove both callbacks
          if (!keepAliveMessages.contains(id)) {
            try {
              messageCallbacks.remove(id);
              messageErrorCallbacks.remove(id);
            } catch (e, s) {
              _logw('error removing message callbacks: $e\n$s');
            }
          }
        }
        break;
      //{msg: changed, collection: stream-room-messages, id: id, fields: {eventName: 657c4ed42995977855b545e8, args: [{_id: 93nMhvDR728ADcsCF, rid: 657c4ed42995977855b545e8, msg: a, ts: {$date: 1702743609088}, u: {_id: iYoGcEJj4gvM5zdRC, username: coolboi, name: coolboi}, _updatedAt: {$date: 1702743609197}, urls: [], mentions: [], channels: [], md: [{type: PARAGRAPH, value: [{type: PLAIN_TEXT, value: a}]}]}]}}]
      case 'changed':
        if(message.containsKey('collection')) {
          if (message['collection'] == 'stream-room-messages') {
            //get channel id
            String channelId = message['fields']?['args']?[0]?['rid']??'';
            _logd('stream-room-messages: channelId: $channelId');
            if(channelId.isEmpty) {
              _logw('stream-room-messages: channelId is empty');
            } else {
              //find all subIds for this channelId
              List<String> subIds = [];
              roomMessageSubscriptions.forEach((key, value) {
                if(value == channelId) {
                  subIds.add(key);
                }
              });
              _logd('stream-room-messages: subIds: $subIds');
              for (var subId in subIds) {
                _logd('stream-room-messages: firing callback for subId: $subId');
                if (messageStatuses.containsKey(subId)) {
                  messageCallbacks[subId]!(message);
                }
              }
            }
          }
        }
      /// received when a subscription is ready
      case 'ready':
        if(message.containsKey('subs')) {
          for (var subId in message['subs']) {
            _logd('ready: firing callback for subId: $subId');
            if (messageCallbacks.containsKey(subId)) {
              messageCallbacks[subId]!(message);
            }
          }
        }
        break;

      default:
        //fire callback
      _logd('firing callback for message: $message');
        if (message.containsKey('id')) {
          if (messageStatuses.containsKey(message['id']??'')) {
            messageStatuses[message['id']??''] = RocketMessageStatus.responded;
            messageCallbacks[message['id']??'']!(message);
          }
        }
        // remove both callbacks
        if (message.containsKey('id') && !keepAliveMessages.contains(message['id']??'')) {
          try {
            messageCallbacks.remove(message['id']??'');
            messageErrorCallbacks.remove(message['id']??'');
          } catch (e, s) {
            _logw('error removing message callbacks: $e\n$s');
          }
        }
        break;
    }
  }

  static Map<String, RocketMessageStatus> messageStatuses = {};
  static Map<String, Function(Map response)> messageCallbacks = {};
  static Map<String, Function(Map response)> messageErrorCallbacks = {};
  static List<String> keepAliveMessages = [];
  static Map<String, String> roomMessageSubscriptions = {}; //subId <-> channelId but only for stream-room-messages

  static String generateMessageId() {
    //return an 8 digit random number. Ensure that the number is unique
    //by checking that it doesn't already exist in the map.keys
    int id = Random().nextInt(99999999);
    while (messageStatuses.containsKey(id)) {
      id = Random().nextInt(99999999);
    }
    return id.toString();
  }

  static String sendMessage(
      Map<String, dynamic> message, String typeOfCommunication,
      {Function(Map response)? onResponse, Function(Map errorResponse)? onError, bool keepAlive = false, String precalculatedId = ''}) {
    if (!_connected) {
      throw Exception('Socket not connected. Connect to socket before sending messages');
    }
    String id = precalculatedId;
    if(id.isEmpty) {
      id = generateMessageId();
    }
    try {
      //construct a message
      Map<String, dynamic> msg = {
        'msg': typeOfCommunication,
        'id': id,
      };
      msg.addAll(message);
      _channel.sink.add(jsonEncode(msg));
      messageStatuses[id] = RocketMessageStatus.sent;
      messageCallbacks[id] = onResponse ?? (Map response) {};
      messageErrorCallbacks[id] = onError ?? (Map errorResponse) {};
      if (keepAlive) {
        keepAliveMessages.add(id);
      }
      _logd('message sent: $msg');
    } catch (e, s) {
      _loge('sendMessage error: $e\n$s');
      messageStatuses[id] = RocketMessageStatus.failed;
      if (onError != null) {
        onError({
          'error': e.toString(),
        });
      }
    }
    return id;
  }

  static Future closeConnection() async {
    try {
      _logd('closing socket connection');
      await _channel.sink.close();
      _connected = false;
      connectionEstablished = false;
    } catch (e, s) {
      _loge('closeConnection error: $e\n$s');
    }
  }

  static void handlePingMessages() {
    _logd('handlePingMessages');
    sendMessage({}, 'pong');
  }

  static Future sendConnectMessage() async {
    assert(_connected);
    try {
      _logd('sending connect message');
      //send message does not return id
      sendMessage({
        'version': '1',
        'support': ['1']
      }, 'connect');
    } catch (e, s) {
      _loge('sendConnectMessage error: $e\n$s');
    }
  }
}
