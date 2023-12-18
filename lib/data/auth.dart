part of flutter_rocketchat;

class _Auth {
  static bool _isAuthenticated = false;

  //important auth data
  static String userId = '', authToken = '';

  static bool _realtimeApiAuthenticated = false;

  static void setIsAuthenticated(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
  }

  static bool isAuthenticated() {
    return _isAuthenticated && authToken.isNotEmpty && userId.isNotEmpty;
  }

  /// Login with username and password
  ///
  /// [username] is the username to login with
  ///
  /// [password] is the password to login with
  ///
  /// Returns a [RocketProfile] object with the user's profile data
  ///
  /// If the login fails, the [RocketProfile] object will have an error message
  ///
  /// If the login is successful, the [RocketProfile] object will have the user's profile data.
  /// Additionally, the [authToken] and [userId] will be set.
  /// This is the only way to set these values apart from [loginUsingResumeToken]
  ///
  /// It is up to the developer using this package to store the [authToken] and
  /// [userId] for future use.
  ///
  /// The developer may also choose to store the [authToken] and [userId]
  /// in a secure storage to persist across sessions for a better UX.
  static Future<RocketProfile> loginWithUserAndPassword(
      String username, String password) async {
    try {
      RResponse response = await _Requests.post(
        _UrlProvider.login,
        body: {
          'user': username,
          'password': password,
        },
      );
      _logd('loginWithUserAndPassword response: $response');
      if (response.success) {
        Map<String, dynamic> data = response.data;
        RocketProfile rocketProfile = RocketProfile.fromJson(data);
        authToken = rocketProfile.authToken;
        userId = rocketProfile.userId;
        return rocketProfile;
      } else {
        return RocketProfile.createErrorProfile(
            errorMessage:
                "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e, s) {
      _loge('loginWithUserAndPassword: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  static Future<RocketProfile> fetchProfile() async {
    try {
      RResponse response = await _Requests.get(_UrlProvider.me, '');
      _logd('fetchProfile response: $response');
      if (response.success) {
        Map<String, dynamic> data = response.data;
        return RocketProfile.fromMeResponse(data);
      } else {
        return RocketProfile.createErrorProfile(
            errorMessage:
                "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e, s) {
      _loge('fetchProfile: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  static Future<RocketProfile> loginUsingResumeToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Resume token cannot be empty');
    }
    try {
      RResponse response = await _Requests.post(
        _UrlProvider.login,
        body: {
          'resume': token,
        },
      );
      _logd('loginUsingResumeToken response: $response');
      if (response.success) {
        Map<String, dynamic> data = response.data;
        RocketProfile rocketProfile = RocketProfile.fromJson(data);
        authToken = rocketProfile.authToken;
        userId = rocketProfile.userId;
        return rocketProfile;
      } else {
        return RocketProfile.createErrorProfile(
            errorMessage:
                "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e, s) {
      _loge('loginUsingResumeToken: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  /// https://developer.rocket.chat/reference/api/realtime-api/method-calls/authentication/login
  static void authenticateRealtimeWithResumeToken(String token,
      {Function(String authToken, int tokenExpiry, String userId)? onConnected,
      Function(Map errorResponse)? onError}) {
    if (token.isEmpty) {
      throw Exception('Resume token cannot be empty');
    }
    if (!_SocketHelper.connectionEstablished) {
      throw Exception(
          'Realtime API socket not connected. Connect to socket before sending messages');
    }
    try {
      _logd('authenticating realtime api with resume token');
      //send message does not return id
      _SocketHelper.sendMessage(
        {
          'method': 'login',
          "params": [
            {"resume": token}
          ],
        },
        'method',
        onResponse: (Map response) {
          _logd('authenticateRealtimeWithResumeToken response: $response');
          if (response['msg'] == 'result') {
            _realtimeApiAuthenticated = true;
            //update auth token
            authToken = response['result']?['token'] ?? '';
            userId = response['result']?['id'] ?? '';
            if (onConnected != null) {
              onConnected(authToken,
                  response['result']?['tokenExpires']['\$date'] ?? 0, userId);
            }
          } else {
            _realtimeApiAuthenticated = false;
            if (onError != null) {
              onError(response['error']);
            }
          }
        },
        onError: (Map errorResponse) {
          _loge('authenticateRealtimeWithResumeToken error: $errorResponse');
          _realtimeApiAuthenticated = false;
          if (onError != null) {
            onError(errorResponse);
          }
        },
      );
    } catch (e, s) {
      _loge('authenticateRealtimeWithResumeToken error: $e\n$s');
    }
  }

  static Future<bool> updateProfile({
    String name = '',
    String email = '',
    String username = '',
    String bio = '',
    String statusType = '',
    String statusText = '',
    String nickname = '',
  }) async {
    if (!isAuthenticated()) {
      throw Exception('User not authenticated');
    }
    Map<String, String> body = {};
    if (name.isNotEmpty) {
      body['name'] = name;
    }
    if (email.isNotEmpty) {
      body['email'] = email;
    }
    if (username.isNotEmpty) {
      body['username'] = username;
    }
    if (bio.isNotEmpty) {
      body['bio'] = bio;
    }
    if (statusType.isNotEmpty) {
      body['status'] = statusType;
    }
    if (statusText.isNotEmpty) {
      body['statusText'] = statusText;
    }
    if (nickname.isNotEmpty) {
      body['nickname'] = nickname;
    }
    if (body.isEmpty) {
      throw Exception('No data to update. Not making request');
    }
    try {
      RResponse response = await _Requests.post(
        _UrlProvider.updateOwnBasicInfo,
        body: {
          'data': body,
        },
      );
      _logd('updateProfile response: $response');
      if (response.success) {
        return true;
      } else {
        return false;
      }
    } catch (e, s) {
      _loge('updateProfile: $e\n$s');
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<bool> updateSelfAvatar(String avatarUrl) async {
    if (!isAuthenticated()) {
      throw Exception('User not authenticated');
    }
    if (avatarUrl.isEmpty) {
      throw Exception('Avatar url cannot be empty');
    }
    try {
      RResponse response = await _Requests.post(
        _UrlProvider.updateAvatar,
        body: {
          'avatarUrl': avatarUrl,
        },
      );
      _logd('updateSelfAvatar response: $response');
      if (response.success) {
        return true;
      } else {
        return false;
      }
    } catch (e, s) {
      _loge('updateSelfAvatar: $e\n$s');
      throw Exception('Error updating avatar: $e');
    }
  }

  static Future<bool> logout() async {
    try {
      RResponse response = await _Requests.post(
        _UrlProvider.logout,
      );
      _logd('logout response: $response');
      if (response.success) {
        return true;
      } else {
        return false;
      }
    } catch (e, s) {
      _loge('logout: $e\n$s');
      return false;
    }
  }
}
