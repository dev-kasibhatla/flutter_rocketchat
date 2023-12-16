part of flutter_rocketchat;

enum RocketMessageStatus {
  sent,
  responded,
  failed,
}

class _SocketHelper {
  static late IOWebSocketChannel _channel;
  static bool _connected = false;
  static bool connectionEstablished = false;
  static String sessionId = '';

  static Future init() async {
    assert(_UrlProvider._websocketUrl.isNotEmpty);
    messageStatuses = {};
    try {
      _channel = IOWebSocketChannel.connect(
          Uri.parse(_UrlProvider._websocketUrl),
          connectTimeout: _Durations.socketConnectTimeout);

      await _channel.ready;
      _connected = true;
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
          },
          cancelOnError: true,
          onDone: () {
            _logd('socket closed');
            _connected = false;
            connectionEstablished = false;
          });
    } catch (e, s) {
      _loge('socket init error: $e\n$s');
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
      default:
        //fire callback
        if (message.containsKey('id')) {
          if (messageStatuses.containsKey(message['id'])) {
            messageStatuses[message['id']] = RocketMessageStatus.responded;
            messageCallbacks[message['id']]!(message);
          }
        }
        break;
    }
  }

  static Map<int, RocketMessageStatus> messageStatuses = {};
  static Map<int, Function(Map response)> messageCallbacks = {};

  static int generateMessageId() {
    //return an 8 digit random number. Ensure that the number is unique
    //by checking that it doesn't already exist in the map.keys
    int id = Random().nextInt(99999999);
    while (messageStatuses.containsKey(id)) {
      id = Random().nextInt(99999999);
    }
    return id;
  }

  static void sendMessage(
      Map<String, dynamic> message, String typeOfCommunication,
      {Function(Map response)? onResponse, Function(String error)? onError}) {
    if (!_connected) {
      throw Exception('Socket not connected. Connect to socket before sending messages');
    }
    int id = generateMessageId();
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
      _logd('message sent: $msg');
    } catch (e, s) {
      _loge('sendMessage error: $e\n$s');
      messageStatuses[id] = RocketMessageStatus.failed;
      if (onError != null) {
        onError(e.toString());
      }
    }
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
