part of flutter_rocketchat;

class RocketProfile {
  //{userId: KTZEtNKBz2wjDN3Eg, authToken: w6dz1j1jNi7W1COypDkp0WYqs4BNTo-P3H36nbischw, me: {_id: KTZEtNKBz2wjDN3Eg, services: {password: {bcrypt: $2b$10$2nM/2ZXfFVmtFtC6g1iO5OiZLY8ymcQCfW2zQpk9oZnKNrcnlMCKO}, email2fa: {enabled: true}}, emails: [{address: 1604@cricinshots.in, verified: false}], status: offline, active: true, _updatedAt: 2023-12-14T08:58:29.549Z, roles: [user], name: suiiiiiiiii, username: player160433, statusConnection: offline, utcOffset: 5.5, settings: {profile: {}, preferences: {enableAutoAway: true, idleTimeLimit: 300, desktopNotificationRequireInteraction: false, desktopNotifications: all, pushNotifications: all, unreadAlert: false, useEmojis: true, convertAsciiEmoji: true, autoImageLoad: true, saveMobileBandwidth: true, collapseMediaByDefault: false, hideUsernames: false, hideRoles: false, hideFlexTab: false, displayAvatars: true, sidebarGroupByType: true, themeAppearence: dark, sidebarViewMode: medium, sidebarDisplayAvatar: true, sidebarShowUnread: false, sidebarSortby: activity, showThreadsInMainChannel: false, alsoSendThreadToChannel: default, sidebarShowFavorites: true, sendOnEnter: normal, emailNotificationMode: mentions, newRoomNotification: door, newMessageNotification: chime, muteFocusedConversations: true, notificationsSoundVolume: 100, omnichannelTranscriptEmail: false, notifyCalendarEvents: true}}, avatarUrl: https://rchat.cricinshots.in/avatar/player160433}}}, requestUrl: https://rchat.cricinshots.in/api/v1/login}
  String _userId, _authToken, _name, _username, _email, _photoUrl;
  List<String> _roles = [];

  bool error = false;
  String errorMessage = '';

  RocketProfile({
    required String name,
    required String email,
    required String photoUrl,
    required String userId,
    required String authToken,
    List<String> roles = const [],
    String username = '',
    this.error = false,
    this.errorMessage = '',
  })  : _name = name,
        _email = email,
        _photoUrl = photoUrl,
        _userId = userId,
        _authToken = authToken,
        _roles = roles,
        _username = username {
    _photoUrl = "${_UrlProvider._baseUrl}/avatar/$userId?format=png&size=50";
  }

  factory RocketProfile.fromJson(Map<String, dynamic> json, {bool error = false, String errorMessage = ''}) {
    _logd("creating a RocketProfile from json: ${jsonEncode(json)}");
    return RocketProfile(
      name: json['data']?['me']?['name']??'',
      email: json['data']?['me']?['emails']?[0]?['address']??'',
      photoUrl: json['data']?['me']?['avatarUrl']??'',
      userId: json['data']?['userId']??'',
      authToken: json['data']?['authToken']??'',
      roles: (json['data']?['me']?['roles']??[]).cast<String>(),
      username: json['data']?['me']?['username']??'',
      error: error,
      errorMessage: errorMessage,
    );
  }

  factory RocketProfile.fromMeResponse (Map<String, dynamic> json, {bool error = false, String errorMessage = ''}) {
    _logd("creating a RocketProfile from me json: ${jsonEncode(json)}");
    return RocketProfile(
      name: json['name']??'',
      email: json['emails']?[0]?['address']??'',
      photoUrl: json['avatarUrl']??'',
      userId: json['_id']??'',
      authToken: '',
      roles: (json['roles']??[]).cast<String>(),
      username: json['username']??'',
      error: error,
      errorMessage: errorMessage,
    );
  }

  factory RocketProfile.fromSavedMap (Map<String, dynamic> json) {
    _logd("creating a RocketProfile from saved json: ${jsonEncode(json)}");
    return RocketProfile(
      name: json['name']??'',
      email: json['email']??'',
      photoUrl: json['photoUrl']??'',
      userId: json['userId']??'',
      authToken: json['authToken']??'',
      roles: (json['roles']??[]).cast<String>(),
      username: json['username']??'',
      error: json['error']??false,
      errorMessage: json['errorMessage']??'',
    );
  }

  factory RocketProfile.basicUserDataOnly ({required String id, required String name, required String username, required String photoUrl}) {
    return RocketProfile(
      name: name,
      email: '',
      photoUrl: photoUrl,
      userId: id,
      authToken: '',
      roles: [],
      username: username,
      error: false,
      errorMessage: '',
    );
  }

  RocketProfile.createErrorProfile({required this.errorMessage}) :
    _userId = '',
    _authToken = '',
    _name = '',
    _username = '',
    _email = '',
    _photoUrl = '',
    _roles = [],
    error = true;
  
  @override
  String toString() {
    return "${toMap()}";
  }

  Map<String, dynamic> toMap() => {
        'name': _name,
        'email': _email,
        'photoUrl': _photoUrl,
        'userId': _userId,
        'authToken': _authToken,
        'roles': _roles,
        'username': _username,
        'error': error,
        'errorMessage': errorMessage,
      };

  //get methods
  String get name => _name;
  String get email => _email;
  String get photoUrl => _photoUrl;
  String get userId => _userId;
  String get authToken => _authToken;
  List<String> get roles => _roles;
  String get username => _username;

}
