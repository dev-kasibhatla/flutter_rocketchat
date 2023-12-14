part of flutter_rocketchat;

enum _StorageKeys {
  userProfiles,
  messages,
}

class _StorageProvider {
  static Directory? _appDirectory;
  static const String prefix = 'rchat_';
  static Future init() async {
    _appDirectory = await getApplicationDocumentsDirectory();
  }

  static Future<void> write(_StorageKeys key, String value) async {
    assert(_appDirectory != null);
    try {
      //convert value to base64
      String convertedValue = base64Encode(utf8.encode(value));
      File file = File('${_appDirectory!.path}/$prefix${key.name}');
      await file.writeAsString(convertedValue);
      _logd('wrote to $key');
    } catch (e, s) {
      _loge('write: $e\n$s');
    }
  }

  static Future<String> read(_StorageKeys key) async {
    assert(_appDirectory != null);
    try {
      File file = File('${_appDirectory!.path}/$prefix${key.name}');
      //check if file exists
      if (!await file.exists()) {
        _logi('read: $key does not exist');
        return '';
      }
      String? value = await file.readAsString();
      if ((value ?? '').isNotEmpty) {
        //convert value from base64
        String convertedValue = utf8.decode(base64Decode(value));
        _logd('read from $key');
        return convertedValue;
      }
    } catch (e, s) {
      _loge('read: $e\n$s');
    }
    return '';
  }
}
