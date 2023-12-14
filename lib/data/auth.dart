part of flutter_rocketchat;

class _Auth {
  static bool _isAuthenticated = false;

  //important auth data
  static String userId='', authToken='';

  static void setIsAuthenticated(bool isAuthenticated) {
    _isAuthenticated = isAuthenticated;
  }

  static bool isAuthenticated() {
    return _isAuthenticated && authToken.isNotEmpty && userId.isNotEmpty;
  }

  static Future<RocketProfile> loginWithUserAndPassword(String username, String password) async {
    try{
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
        return RocketProfile.createErrorProfile(errorMessage: "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e,s) {
      _loge ('loginWithUserAndPassword: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  static Future<RocketProfile> fetchProfile() async {
    try{
      RResponse response = await _Requests.get(
        _UrlProvider.me, ''
      );
      _logd('fetchProfile response: $response');
      if (response.success) {
        Map<String, dynamic> data = response.data;
        return RocketProfile.fromMeResponse(data);
      } else {
        return RocketProfile.createErrorProfile(errorMessage: "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e,s) {
      _loge ('fetchProfile: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  static Future<RocketProfile> loginUsingResumeToken(String token) async {
    try{
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
        return RocketProfile.createErrorProfile(errorMessage: "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } catch (e,s) {
      _loge ('loginUsingResumeToken: $e\n$s');
      return RocketProfile.createErrorProfile(errorMessage: "$e");
    }
  }

  static Future<bool> logout () async {
    try{
      RResponse response = await _Requests.post(
        _UrlProvider.logout,
      );
      _logd('logout response: $response');
      if (response.success) {
        return true;
      } else {
        return false;
      }
    } catch (e,s) {
      _loge ('logout: $e\n$s');
      return false;
    }
  }
}