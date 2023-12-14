part of flutter_rocketchat;

class _Requests {
  static late Dio dio;
  static late PersistCookieJar cj;

  static setDioTimeOut({bool download = false}) {
    if (download) {
      dio.options.connectTimeout = _Durations.networkDownloadConnectTimeout;
      dio.options.receiveTimeout = _Durations.networkDownloadReceiveTimeout;
      dio.options.sendTimeout = _Durations.networkDownloadSendTimeout;
    } else {
      dio.options.connectTimeout = _Durations.networkConnectTimeout;
      dio.options.receiveTimeout = _Durations.networkReceiveTimeout;
      dio.options.sendTimeout = _Durations.networkSendTimeout;
    }
  }

  static Future init() async {
    dio = Dio();
    await initCookies();
    setDioTimeOut();
    //cookies
    dio.interceptors.add(CookieManager(cj));
    //request caching
    await initRequestCaching();
    _logd("requests initialized");
  }

  static Future clearCookies() async {
    await cj.deleteAll();
    _logd('cookies cleared forcefully');
  }

  static Future initCookies() async {
    Directory tempDir = await getApplicationSupportDirectory();
    String tempPath = tempDir.path;
    _logd("app directory $tempPath");
    cj = PersistCookieJar(
      storage: FileStorage(tempPath),
      ignoreExpires: true, //do not save/load cookies that have expired.
    );
  }

  static initRequestCaching() async {
    Directory tempDir = await getTemporaryDirectory();
    final options = CacheOptions(
      store: BackupCacheStore(
        primary: MemCacheStore(),
        secondary: HiveCacheStore(
          tempDir.path,
          hiveBoxName: 'requests_cache',
        ),
      ),
      allowPostMethod: true,
      priority: CachePriority.normal,
      hitCacheOnErrorExcept: [401, 403, 500],
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      policy: CachePolicy.request,
    );
    dio.interceptors.add(DioCacheInterceptor(options: options));
  }

  static Future<RResponse> get(Uri uri, String body) async {
    Response response;

    //response params
    int statusCode = 0;
    String statusMessage = '';
    late var data;
    bool success = false;
    Map responseHeaders = {};

    if(_Auth.authToken.isNotEmpty) {
      dio.options.headers['X-Auth-Token'] = _Auth.authToken;
      dio.options.headers['X-User-Id'] = _Auth.userId;
    }

    _logd(
        'sending a GET request to ${uri.toString()} with params $body and headers ${dio.options.headers}');
    // logd(dio.options.headers);
    try {
      response = await dio.get(
        uri.toString() + body,
      );

      statusCode = (response.statusCode) ?? 0;
      _logd("response status $statusCode");
      responseHeaders = response.headers.map;
      if (statusCode == 200) {
        // logd("response status $statusCode");
        success = true;
        data = response.data;
      } else {
        success = false;
        data = response.data;
        _logw(
            "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } on DioException catch (e) {
      _loge("Dio Error was caught -> $e for ${uri.toString()}");
      success = false;
      statusCode = e.response?.statusCode ?? 0;
      data = e.response?.data ?? {};
      statusMessage = e.message ?? '[dioErr] no message recd';
      responseHeaders = e.response?.headers.map ?? {};
    } catch (e) {
      _loge("Error caught -> $e");
      success = false;
      statusMessage = "Error communicating with the server";
      data = {};
      statusCode = 0;
    }
    _logd('creating a response object');
    return RResponse(
        statusCode: statusCode,
        data: data,
        success: success,
        statusMessage: statusMessage,
        requestUrl: uri.toString(),
        responseHeaders: responseHeaders);
  }

  static Future<RResponse> post(Uri uri, {Map<String, dynamic> body = const {}}) async {
    Response response;

    //response params
    int statusCode = 0;
    String statusMessage = '';
    dynamic data = {};
    bool success = false;
    Map responseHeaders = {};

    if(_Auth.authToken.isNotEmpty) {
      dio.options.headers['X-Auth-Token'] = _Auth.authToken;
      dio.options.headers['X-User-Id'] = _Auth.userId;
    }

    _logd(
        'sending a POST request to ${uri.toString()} with params $body and headers ${dio.options.headers}');
    // logd(dio.options.headers);
    try {
      response = await dio.post(
        uri.toString(),
        data: body,
      );

      statusCode = (response.statusCode) ?? 0;
      _logd("response status $statusCode");
      responseHeaders = response.headers.map;
      if (statusCode == 200) {
        success = true;
        data = response.data;
      } else {
        success = false;
        data = response.data;
        _logw(
            "${response.data}\n${response.statusCode}\n${response.statusMessage}");
      }
    } on DioException catch (e) {
      _loge("Dio Error was caught -> $e  for ${uri.toString()}");
      success = false;
      statusCode = e.response?.statusCode ?? 0;
      data = e.response?.data ?? {};

      statusMessage = e.message ?? '[dioErr] no message recd';
      _logw(e.message);
      _logw(e.response?.data);
      responseHeaders = e.response?.headers.map ?? {};
      _logd('printing stack trace now - post');
    } catch (e) {
      _loge("Error caught -> $e");
      success = false;
      statusMessage = "Error communicating with the server";
      data = {};
      statusCode = 0;
    }
    // logd('creating a response object');
    RResponse res = RResponse(
        statusCode: statusCode,
        data: data,
        success: success,
        statusMessage: statusMessage,
        requestUrl: uri.toString(),
        responseHeaders: responseHeaders);
    _logd('response object created');
    if (res.statusCode != 200 && res.statusCode != 401) {
      _logd('status code is not 200 or 401.');
    }
    return res;
  }

  static Future<List<String>> getCookiesList() async {
    try {
      List<Cookie> cookiesRaw = await cj.loadForRequest(_UrlProvider.me);
      List<String> cookies = [];
      for (var element in cookiesRaw) {
        cookies.add("$element");
      }
      return cookies;
    } catch (e) {
      _logw('error getting cookies list: $e');
      return Future.value([]);
    }
  }
}

class RResponse {
  int statusCode = 0;
  bool success = false;
  String statusMessage = '';
  String humanMessage = '';
  dynamic data = {};
  String requestUrl = '';
  var responseHeaders = {};
  //add headers
  RResponse({
    required this.statusCode,
    this.statusMessage = '',
    required this.data,
    this.humanMessage = '',
    required this.success,
    required this.requestUrl,
    required this.responseHeaders,
  }) {
    // logd("creating a CResponse");
    if (statusCode >= 200 && statusCode < 400) {
      success = true;
      //set is authenticated
      _Auth.setIsAuthenticated(true);
    } else if (statusCode == 401) {
      _logw('401 status caught');
      _Auth.setIsAuthenticated(false);
    } else {
      success = false;
    }
  }

  @override
  String toString() {
    return "${toMap()}";
  }

  Map toMap() {
    return {
      'statusCode': statusCode,
      'success': success,
      'statusMessage': statusMessage,
      'humanMessage': humanMessage,
      'data': data,
      'requestUrl': requestUrl,
    };
  }
}
