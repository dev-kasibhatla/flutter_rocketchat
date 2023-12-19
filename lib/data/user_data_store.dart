part of flutter_rocketchat;

class _UserDataStore {
  static Map <String, RocketProfile> _profiles = {};

  static Future init() async {
    _profiles = {};
    await _loadProfilesFromStorage();
  }

  static int lastSaveToStorageTimeStamp = 0;
  static int saveToStorageInterval = 1000 * 60; // 1 minute

  //fetch and store all user profiles from the server
  static void addUserToStore(String id, String username, String name, String photoUrl) {
    _profiles[id] = RocketProfile.basicUserDataOnly(id: id, name: name, username: username, photoUrl: photoUrl);
    if (_profiles.containsKey(id)) {
    } else {
      _saveProfilesToStorage();
    }
  }

  static void batchAddUsersToStore(List<dynamic> users) {
    for (Map user in users) {
      addUserToStore(user['_id']??'', user['username']??'', user['name']??'', user['avatarUrl']??'');
    }
    _saveProfilesToStorage();
    _logd('batchAddUsersToStore: added ${users.length} users to store');
  }

  static Future<void> precacheUsersFromChannel({required String channelId, List<String> status = const [], int count = 500}) async {
    try{
      String params = '?roomId=$channelId&count=$count';
      if(status.isNotEmpty) {
        params += '&status[]=${status.join(',')}';
      }
      RResponse response = await _Requests.get(_UrlProvider.allChannelUsers, params);
      _logd('precacheUsersFromChannel response: ${response.data}');
      if(response.success) {
        batchAddUsersToStore(response.data['members']??[]);
      }
    } catch (e,s) {
      _loge('precacheUsersFromChannel: $e\n$s');
    }
  }

  static Future<void> _loadProfilesFromStorage() async {
    String profilesJson = await _StorageProvider.read(_StorageKeys.userProfiles);
    if (profilesJson.isEmpty) {
      _logi('no profiles found in storage');
      return;
    }
    try {
      Map<String, dynamic> profilesMap = jsonDecode(profilesJson);
      for (var key in profilesMap.keys) {
        _profiles[key] = RocketProfile.fromSavedMap(profilesMap[key]);
      }
      _logd('loaded ${_profiles.length} profiles from storage');
    } catch (e, s) {
      _loge('loadProfilesFromStorage: $e\n$s');
      _profiles = {};
    }
  }

  static Future<void> _saveProfilesToStorage() async {

    if(DateTime.now().millisecondsSinceEpoch - lastSaveToStorageTimeStamp < saveToStorageInterval) {
      _logd('saveProfilesToStorage: skipping save to storage');
      return;
    }
    lastSaveToStorageTimeStamp = DateTime.now().millisecondsSinceEpoch;

    try {
      Map<String, dynamic> profilesMap = {};
      for (var key in _profiles.keys) {
        profilesMap[key] = _profiles[key]!.toMap();
      }
      String profilesJson = jsonEncode(profilesMap);
      await _StorageProvider.write(_StorageKeys.userProfiles, profilesJson);
      _logd('saved ${_profiles.length} profiles to storage');
    } catch (e, s) {
      _loge('saveProfilesToStorage: $e\n$s');
    }
  }
}