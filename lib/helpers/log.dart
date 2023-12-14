part of flutter_rocketchat;
enum LogType { debug, info, warning, error, none }

LogType _consoleLogLevel = LogType.debug;
LogType _storeLogLevel = LogType.info;
const int _maxLogSize = 1000;

const String _prefix = '[flutter_rocketchat]';

class _LogMessage {
  LogType logType;
  List<dynamic> messages;
  int timestamp = 0; // in milliseconds

  _LogMessage(this.logType, this.messages) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
    printToConsole();
    storeLog();
  }

  void printToConsole() {
    if (logType.index >= _consoleLogLevel.index) {
      if (kDebugMode) {
        print('$_prefix [$timestamp] ${logType.name}: $messages');
      }
    }
  }

  void storeLog() {
    if (logType.index >= _storeLogLevel.index) {
      if (_logs.length > _maxLogSize) {
        _logs.removeRange(0, _logs.length - _maxLogSize);
      }
      _logs.add(this);
    }
  }
}

/// Log storage
List<_LogMessage> _logs = [];

//do not export this function to the outside world
_logi (Object? messages) {
  _logs.add(_LogMessage(LogType.info, [messages]));
}

_logd (Object? messages) {
  _logs.add(_LogMessage(LogType.debug, [messages]));
}

_logw (Object? messages) {
  _logs.add(_LogMessage(LogType.warning, [messages]));
}

_loge (Object? messages) {
  _logs.add(_LogMessage(LogType.error, [messages]));
}