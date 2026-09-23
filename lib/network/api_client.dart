import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Gixa/common/api.dart';
import 'package:Gixa/network/api_endpoints.dart';
import 'package:Gixa/network/app_exception.dart';
import 'package:Gixa/services/jwt_token_helper.dart';
import 'package:Gixa/services/logout_services.dart';
import 'package:Gixa/services/token_services.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:http/http.dart' hide MultipartFile, Response;
import 'package:Gixa/common/widgets/app_snackbar.dart';

import '../common/Error/error_controller.dart';

class RequestPolicy {
  final Duration? ttl;
  final bool dedupe;
  final bool forceRefresh;

  const RequestPolicy({
    this.ttl,
    this.dedupe = true,
    this.forceRefresh = false,
  });
}

class _CachedGetResponse {
  final dynamic data;
  final DateTime expiresAt;
  final String endpoint;

  const _CachedGetResponse({
    required this.data,
    required this.expiresAt,
    required this.endpoint,
  });

  bool get isFresh => DateTime.now().isBefore(expiresAt);
}

class ApiClient {
  ApiClient._();

  static const String _retryAfterRefreshKey = 'retry_after_refresh';
  static final Map<String, Completer<dynamic>> _inFlightGets = {};
  static final Map<String, _CachedGetResponse> _getCache = {};
  static final Map<String, String> _getRequestEndpoints = {};

  static BaseOptions _baseOptions() {
    return BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );
  }

  static final CookieJar cookieJar = CookieJar();

  static final Dio _dio = Dio(_baseOptions())
    ..interceptors.add(CookieManager(cookieJar))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // final token = await TokenService.getAccessToken();

          // print("");
          // print("=========== API REQUEST ===========");
          // print("URL: ${options.uri}");
          // print("METHOD: ${options.method}");
          // print("TOKEN EXISTS: ${token != null}");
          // print("TOKEN: $token");
          // print("HEADERS: ${options.headers}");
          // print("DATA: ${options.data}");
          // print("==================================");
          // print("");

          if (_requiresAuth(options.path)) {
            final usableToken = await _getUsableAccessToken();

            if (usableToken != null && usableToken.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $usableToken';
            }
          }

          options.headers['Accept'] = 'application/json';

          return handler.next(options);
        },
        onError: (error, handler) async {
          print("");
          print("=========== API ERROR ===========");
          print("URL: ${error.requestOptions.uri}");
          print("METHOD: ${error.requestOptions.method}");
          print("REQUEST DATA: ${error.requestOptions.data}");
          print("STATUS CODE: ${error.response?.statusCode}");
          print("SERVER RESPONSE: ${error.response?.data}");
          print("=================================");
          print("");

          if (_shouldRefreshAndRetry(error)) {
            final token = await TokenService.getAccessToken();

            /// GUEST USER
            if (token == null || token.isEmpty) {
              print("GUEST USER 401 - NO LOGOUT");

              return handler.next(error);
            }

            /// LOGGED IN USER
            final newAccessToken = await _refreshAccessToken();

            if (newAccessToken != null && newAccessToken.isNotEmpty) {
              try {
                final retryResponse = await _retryRequest(
                  error.requestOptions,
                  newAccessToken,
                );

                return handler.resolve(retryResponse);
              } on DioException catch (retryError) {
                if (retryError.response?.statusCode != 401) {
                  return handler.reject(retryError);
                }
              }
            }

            final errorMessage = _extractErrorMessage(error.response?.data);
            await _handleUnauthorizedSession(errorMessage);

            return handler.reject(error);
          }

          return handler.next(error);
        },
      ),
    );

  static final Dio _refreshDio = Dio(_baseOptions())
    ..interceptors.add(CookieManager(cookieJar));

  static Completer<String?>? _refreshCompleter;

  static String _extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data['message'] is String &&
          data['message'].toString().trim().isNotEmpty) {
        return data['message'].toString();
      }

      if (data['detail'] is String &&
          data['detail'].toString().trim().isNotEmpty) {
        return data['detail'].toString();
      }

      for (final value in data.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    if (data is List && data.isNotEmpty) {
      return data.first.toString();
    }

    if (data is String && data.trim().isNotEmpty) {
      if (data.contains('<!DOCTYPE html>') ||
          data.contains('<html') ||
          data.contains('404 - Gixa')) {
        return 'Data unavailable for this selection (Server returned 404 Not Found).';
      }
      return data;
    }

    return 'Something went wrong. Please try again.';
  }

  static bool _requiresAuth(String endpoint) {
    return endpoint != ApiEndpoints.sendOtp &&
        endpoint != ApiEndpoints.verifyOtp &&
        endpoint != ApiEndpoints.googleLogin &&
        endpoint != ApiEndpoints.registerStudent &&
        endpoint != ApiEndpoints.refreshToken &&
        endpoint != ApiEndpoints.logoutOtherDevice;
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );

      _invalidateForMutation(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> postAllow409(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers, validateStatus: (_) => true),
      );

      print('postAllow409 -> ${response.statusCode} | Data: ${response.data}');

      final data = response.data;
      if (response.statusCode != null &&
          ((response.statusCode! >= 200 && response.statusCode! < 300) ||
              response.statusCode == 409 ||
              (data is Map &&
                  data['error_code'] == 'ALREADY_LOGGED_IN_OTHER_DEVICE'))) {
        _invalidateForMutation(endpoint);
        return Map<String, dynamic>.from(data);
      }

      String errorMessage = 'Request failed (${response.statusCode})';

      if (response.data is Map) {
        final errorData = response.data as Map;

        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        } else if (errorData['non_field_errors'] != null &&
            errorData['non_field_errors'] is List &&
            errorData['non_field_errors'].isNotEmpty) {
          errorMessage = errorData['non_field_errors'][0];
        } else if (errorData.values.isNotEmpty) {
          errorMessage = errorData.values.first.toString();
        }
      }

      print('postAllow409 throwing AppException: $errorMessage');
      throw AppException(message: errorMessage);
    } on DioException catch (e) {
      print('postAllow409 caught DioException: ${e.message}');
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );

      _invalidateForMutation(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> postForm(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final formData = FormData.fromMap(body);

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: {...?headers}),
      );

      _invalidateForMutation(endpoint);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required File file,
    required String fileFieldName,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final formMap = <String, dynamic>{...fields};

      final filename = file.path.split('/').last.split('\\').last;

      formMap[fileFieldName] = await MultipartFile.fromFile(
        file.path,
        filename: filename,
      );

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      _invalidateForMutation(endpoint);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> postMultipartFiles(
    String endpoint, {

    required List<File> files,

    required String fileFieldName,

    required Map<String, dynamic> fields,
  }) async {
    try {
      /// FORM DATA
      final formData = FormData();

      /// NORMAL FIELDS
      fields.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });

      /// MULTIPLE FILES
      for (final file in files) {
        String filename = file.path.split('/').last.split('\\').last;

        /// FIX MISSING EXTENSIONS
        if (!filename.contains('.')) {
          final extension = file.path.split('.').last;

          if (extension.isNotEmpty && extension.length <= 5) {
            filename = "$filename.$extension";
          }
        }

        print("📎 FILE => ${file.path}");

        formData.files.add(
          MapEntry(
            /// IMPORTANT
            /// SAME KEY LIKE POSTMAN
            fileFieldName,

            await MultipartFile.fromFile(
              file.path,

              filename: filename,

              contentType: _getMediaType(file.path),
            ),
          ),
        );
      }

      print(
        "📤 FIELDS => "
        "${formData.fields}",
      );

      print(
        "📤 FILES => "
        "${formData.files}",
      );

      final response = await _dio.post(
        endpoint,

        data: formData,

        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      print(
        "✅ RESPONSE => "
        "${response.data}",
      );

      _invalidateForMutation(endpoint);

      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print(
        "❌ DIO ERROR => "
        "${e.response?.data}",
      );

      print(
        "❌ ERROR MESSAGE => "
        "${e.message}",
      );

      _handleDioError(e);

      return {};
    }
  }

  static MediaType _getMediaType(String path) {
    final lower = path.toLowerCase();

    /// PDF
    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }

    /// DOC
    if (lower.endsWith('.doc')) {
      return MediaType('application', 'msword');
    }

    /// DOCX
    if (lower.endsWith('.docx')) {
      return MediaType(
        'application',

        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      );
    }

    /// PNG
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    /// JPG / JPEG
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    /// XLS
    if (lower.endsWith('.xls')) {
      return MediaType('application', 'vnd.ms-excel');
    }

    /// XLSX
    if (lower.endsWith('.xlsx')) {
      return MediaType(
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
    }

    /// DEFAULT
    return MediaType('application', 'octet-stream');
  }

  static Future<dynamic> delete(
    String endpoint,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _dio.delete(
        endpoint,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );

      _invalidateForMutation(endpoint);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    bool showGlobalNetworkError = true,
    RequestPolicy requestPolicy = const RequestPolicy(),
  }) async {
    final policy = requestPolicy;
    final normalizedEndpoint = _normalizeEndpoint(endpoint);
    final authCacheKey = await _authCacheKeyForEndpoint(endpoint);
    final cacheKey = _buildGetCacheKey(
      endpoint: normalizedEndpoint,
      queryParameters: queryParameters,
      authCacheKey: authCacheKey,
    );

    if (policy.forceRefresh) {
      _removeCachedGet(cacheKey);
    }

    if (policy.ttl != null && !policy.forceRefresh) {
      final cached = _getCache[cacheKey];
      if (cached != null && cached.isFresh) {
        return cached.data;
      }

      if (cached != null && !cached.isFresh) {
        _removeCachedGet(cacheKey);
      }
    }

    Completer<dynamic>? completer;
    if (policy.dedupe && !policy.forceRefresh) {
      final inFlight = _inFlightGets[cacheKey];
      if (inFlight != null) {
        return inFlight.future;
      }

      completer = Completer<dynamic>();
      _inFlightGets[cacheKey] = completer;
      _getRequestEndpoints[cacheKey] = normalizedEndpoint;
    }

    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );

      final data = response.data;

      if (policy.ttl != null) {
        _getCache[cacheKey] = _CachedGetResponse(
          data: data,
          expiresAt: DateTime.now().add(policy.ttl!),
          endpoint: normalizedEndpoint,
        );
        _getRequestEndpoints[cacheKey] = normalizedEndpoint;
      } else {
        _getRequestEndpoints.remove(cacheKey);
      }

      completer?.complete(data);
      return data;
    } on DioException catch (e) {
      final appException = _toAppException(
        e,
        showGlobalNetworkError: showGlobalNetworkError,
      );

      _getRequestEndpoints.remove(cacheKey);

      /// GUEST USER 401
      if (appException.message.trim().isEmpty) {
        print("IGNORING EMPTY APP EXCEPTION");

        completer?.complete({});

        return {};
      }

      completer?.completeError(appException);

      throw appException;
    } finally {
      if (completer != null) {
        _inFlightGets.remove(cacheKey);
      }
    }
  }

  static Future<Map<String, dynamic>> putMultipart(
    String endpoint, {
    required Map<String, dynamic> fields,
  }) async {
    try {
      print('--- PUT MULTIPART REQUEST ---');
      print('Endpoint: ' + endpoint);
      print('Fields: ' + fields.toString());
      final formData = FormData.fromMap(fields);

      final response = await _dio.put(
        endpoint,
        data: formData,
        options: Options(),
      );

      print('--- PUT MULTIPART RESPONSE ---');
      print('Status code: \'${response.statusCode}\'');
      print('Response data: ' + response.data.toString());

      _invalidateForMutation(endpoint);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      print('--- PUT MULTIPART ERROR ---');
      print(e);
      _handleDioError(e);
      return {};
    }
  }

  static Future<Map<String, dynamic>> putMultipartWithFile(
    String endpoint, {
    required File file,
    required String fileFieldName,
    required Map<String, dynamic> fields,
  }) async {
    try {
      final formMap = <String, dynamic>{...fields};

      final filename = file.path.split('/').last.split('\\').last;

      formMap[fileFieldName] = await MultipartFile.fromFile(
        file.path,
        filename: filename,
      );

      final formData = FormData.fromMap(formMap);

      final response = await _dio.put(
        endpoint,
        data: formData,
        options: Options(),
      );

      _invalidateForMutation(endpoint);
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      _handleDioError(e);
      return {};
    }
  }

  static Future<void> clearCookies() async {
    await cookieJar.deleteAll();
  }

  static void clearGetCache() {
    _getCache.clear();
    _inFlightGets.clear();
    _getRequestEndpoints.clear();
  }

  static void invalidateGetCache({
    Iterable<String> endpointPrefixes = const [],
    bool clearAll = false,
  }) {
    if (clearAll) {
      clearGetCache();
      return;
    }

    final prefixes = endpointPrefixes
        .map(_normalizeEndpoint)
        .where((prefix) => prefix.isNotEmpty)
        .toList();

    if (prefixes.isEmpty) return;

    final matchingKeys = _getRequestEndpoints.entries
        .where(
          (entry) => prefixes.any((prefix) => entry.value.startsWith(prefix)),
        )
        .map((entry) => entry.key)
        .toList();

    for (final key in matchingKeys) {
      _removeCachedGet(key);
      _inFlightGets.remove(key);
    }
  }

  static Future<String?> _getUsableAccessToken() async {
    final accessToken = await TokenService.getAccessToken();
    final inspection = JwtTokenHelper.inspect(
      accessToken,
      label: 'api_access_token',
    );

    if (!inspection.hasToken) {
      return null;
    }

    if (inspection.isMalformed) {
      await TokenService.clearTokens();
      return null;
    }

    if (inspection.isValid) {
      return accessToken;
    }

    return _refreshAccessToken();
  }

  static bool _shouldRefreshAndRetry(DioException error) {
    final statusCode = error.response?.statusCode;
    final request = error.requestOptions;

    return statusCode == 401 &&
        _requiresAuth(request.path) &&
        request.extra[_retryAfterRefreshKey] != true;
  }

  static Future<String?> _refreshAccessToken() {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    () async {
      try {
        final refreshToken = await TokenService.getRefreshToken();
        final inspection = JwtTokenHelper.inspect(
          refreshToken,
          label: 'api_refresh_token',
        );

        if (!inspection.hasToken) {
          completer.complete(null);
          return;
        }

        if (inspection.isMalformed || inspection.isExpired) {
          await TokenService.clearTokens();
          completer.complete(null);
          return;
        }

        final safeRefreshToken = refreshToken!;

        final response = await _refreshDio.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': safeRefreshToken},
        );

        final newAccessToken = _extractAccessToken(response.data);
        final newRefreshToken =
            _extractRefreshToken(response.data) ?? safeRefreshToken;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          completer.complete(null);
          return;
        }

        await TokenService.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        completer.complete(newAccessToken);
      } on DioException catch (_) {
        completer.complete(null);
      } catch (_) {
        completer.complete(null);
      } finally {
        if (identical(_refreshCompleter, completer)) {
          _refreshCompleter = null;
        }
      }
    }();

    return completer.future;
  }

  static String? _extractAccessToken(dynamic data) {
    final map = _asMap(data);
    final tokenMap = _asMap(map?['token']);

    return _readTokenValue(tokenMap?['access']) ??
        _readTokenValue(map?['access']) ??
        _readTokenValue(map?['access_token']);
  }

  static String? _extractRefreshToken(dynamic data) {
    final map = _asMap(data);
    final tokenMap = _asMap(map?['token']);

    return _readTokenValue(tokenMap?['refresh']) ??
        _readTokenValue(map?['refresh']) ??
        _readTokenValue(map?['refresh_token']);
  }

  static Map<String, dynamic>? _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return null;
  }

  static String? _readTokenValue(dynamic value) {
    final token = value?.toString().trim();
    if (token == null || token.isEmpty || token == 'null') {
      return null;
    }

    return token;
  }

  static Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String accessToken,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    headers['Authorization'] = 'Bearer $accessToken';

    return _dio.fetch<dynamic>(
      requestOptions.copyWith(
        data: _cloneRequestData(requestOptions.data),
        headers: headers,
        extra: {...requestOptions.extra, _retryAfterRefreshKey: true},
      ),
    );
  }

  static dynamic _cloneRequestData(dynamic data) {
    if (data is FormData) {
      return data.clone();
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    if (data is List) {
      return List<dynamic>.from(data);
    }

    return data;
  }

  static Future<void> _handleUnauthorizedSession([String? message]) async {
    clearGetCache();
    await clearCookies();
    await TokenService.clearTokens();
    await Future.delayed(const Duration(milliseconds: 150));
    await SessionService.forceLogout(message);
  }

  static void _handleDioError(
    DioException e, {
    bool showGlobalNetworkError = true,
  }) {
    final appException = _toAppException(
      e,
      showGlobalNetworkError: showGlobalNetworkError,
    );

    /// GUEST USER 401
    if (appException.message.trim().isEmpty) {
      print("IGNORING EMPTY APP EXCEPTION");

      return;
    }

    // We do not show the full-screen GlobalNetworkError here anymore
    // because it aggressively blocks the app during transient timeouts
    // (e.g., waking up from background). Local UI controllers will catch
    // this AppException and show a graceful Snackbar instead.

    throw appException;
  }

  static AppException _toAppException(
    DioException e, {
    bool showGlobalNetworkError = true,
  }) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (status == 413) {
      return AppException(
        message: 'File size is too large. Please upload a smaller file.',
        debugMessage: e.message,
        statusCode: status,
      );
    }

    if (status == 400 && data is Map) {
      final firstValue = data.values.first;

      if (firstValue is List && firstValue.isNotEmpty) {
        return AppException(message: firstValue.first.toString());
      }

      return AppException(
        message: _extractErrorMessage(data),
        debugMessage: e.message,
        statusCode: status,
      );
    }

    if (status == 401) {
      final token = TokenService.accessTokenSync;

      /// GUEST USER
      if (token == null || token.isEmpty) {
        print("GUEST USER APP EXCEPTION");

        return AppException(
          message: '',
          debugMessage: e.message,
          statusCode: status,
          isNetworkError: false,
        );
      }

      /// LOGGED IN USER
      final serverMessage = _extractErrorMessage(data);
      return AppException(
        message: serverMessage.isNotEmpty
            ? serverMessage
            : 'Your session has expired. Please login again.',
        debugMessage: e.message,
        statusCode: status,
        isNetworkError: false,
      );
    }
    if (status == 403) {
      return AppException(
        message: "You don't have permission to perform this action.",
      );
    }

    if (status == 404) {
      return AppException(
        message: _extractErrorMessage(data),
        debugMessage: e.message,
        statusCode: status,
      );
    }

    if (status == 405) {
      return AppException(
        message: 'Request method not allowed.',
        debugMessage: e.message,
        statusCode: status,
      );
    }

    if (status != null && status >= 500) {
      final serverMsg = _extractErrorMessage(data);
      return AppException(
        message: serverMsg.isNotEmpty && serverMsg != 'Something went wrong. Please try again.'
            ? 'Server error ($status): $serverMsg'
            : 'Server error ($status). Please try again later.',
        debugMessage: e.message,
        statusCode: status,
      );
    }

    if (e.type == DioExceptionType.badCertificate ||
        e.error is HandshakeException) {
      return AppException(
        message: 'Secure connection to the server failed.',
        debugMessage: e.message,
      );
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AppException(
        message: 'The server is taking too long to respond. Please try again.',
        debugMessage: e.message,
        isNetworkError: true,
      );
    }

    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
      return AppException(
        message:
            'Unable to reach the server. Please try again on a different network.',
        debugMessage: e.message,
        isNetworkError: true,
      );
    }

    if (status != null) {
      return AppException(
        message: _extractErrorMessage(data),
        debugMessage: e.message,
        statusCode: status,
      );
    }

    return AppException(
      message: 'Something went wrong. Please try again.',
      debugMessage: e.message,
    );
  }

  static String _buildGetCacheKey({
    required String endpoint,
    required Map<String, dynamic>? queryParameters,
    required String authCacheKey,
  }) {
    final normalizedQuery = _canonicalizeQueryParameters(queryParameters);
    return 'endpoint=$endpoint;auth=$authCacheKey;query=$normalizedQuery';
  }

  static String _canonicalizeQueryParameters(
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) {
      return '';
    }

    final sortedKeys = queryParameters.keys.toList()..sort();
    final normalized = <String, dynamic>{};
    for (final key in sortedKeys) {
      normalized[key] = _normalizeQueryValue(queryParameters[key]);
    }

    return jsonEncode(normalized);
  }

  static dynamic _normalizeQueryValue(dynamic value) {
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      return {
        for (final entry in entries)
          entry.key.toString(): _normalizeQueryValue(entry.value),
      };
    }

    if (value is List) {
      return value.map(_normalizeQueryValue).toList();
    }

    return value;
  }

  static Future<String> _authCacheKeyForEndpoint(String endpoint) async {
    if (!_requiresAuth(endpoint)) {
      return 'guest';
    }

    final token = await TokenService.getAccessToken();
    if (token == null || token.isEmpty) {
      return 'guest';
    }

    return token.hashCode.toString();
  }

  static String _normalizeEndpoint(String endpoint) {
    final uri = Uri.tryParse(endpoint);
    if (uri == null) return endpoint;

    final path = uri.path.isEmpty ? endpoint : uri.path;
    final queryParameters = uri.queryParameters.isEmpty
        ? ''
        : _canonicalizeQueryParameters(uri.queryParameters);

    return queryParameters.isEmpty ? path : '$path?$queryParameters';
  }

  static void _removeCachedGet(String cacheKey) {
    _getCache.remove(cacheKey);
    _getRequestEndpoints.remove(cacheKey);
  }

  static void _invalidateForMutation(String endpoint) {
    final normalizedEndpoint = _normalizeEndpoint(endpoint);

    if (normalizedEndpoint == ApiEndpoints.logout ||
        normalizedEndpoint == ApiEndpoints.logoutOtherDevice) {
      clearGetCache();
      return;
    }

    final prefixes = <String>{};

    if (normalizedEndpoint.startsWith(ApiEndpoints.profile)) {
      prefixes.add(ApiEndpoints.profile);
    }

    if (normalizedEndpoint.startsWith(ApiEndpoints.subscriptionPurchase) ||
        normalizedEndpoint.startsWith(ApiEndpoints.subscriptionCreateOrder) ||
        normalizedEndpoint.startsWith(ApiEndpoints.subscriptionVerifyPayment)) {
      prefixes.add(ApiEndpoints.subscriptionPlans);
      prefixes.add('/api/subscriptions/user/');
      prefixes.add(ApiEndpoints.paymentCredentials);
    }

    if (prefixes.isNotEmpty) {
      invalidateGetCache(endpointPrefixes: prefixes);
    }
  }
}
