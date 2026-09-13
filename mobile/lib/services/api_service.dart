import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;
  SharedPreferences? _prefs;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.apiTimeout,
      receiveTimeout: AppConstants.apiTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired
          removeToken();
        }
        handler.next(error);
      },
    ));
  }

  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    if (_prefs != null) return;
    _prefs = await SharedPreferences.getInstance();

    // Terapkan override server yang disimpan pengguna (bila ada) supaya
    // request pertama sudah menuju URL yang benar.
    final saved = _prefs?.getString(AppConstants.apiBaseUrlKey);
    final normalized = saved == null ? '' : normalizeBaseUrl(saved);
    if (normalized.isNotEmpty) {
      AppConstants.baseUrl = normalized;
      _dio.options.baseUrl = normalized;
    }
  }

  /// Base URL backend yang saat ini dipakai.
  String get baseUrl => _dio.options.baseUrl;

  /// Membersihkan dan menormalkan URL yang diketik pengguna.
  ///
  /// - Menambahkan skema `http://` bila belum ada
  /// - Membuang spasi dan garis miring di akhir
  /// - Menambahkan `/api/v1` bila pengguna hanya menulis domain
  ///
  /// Mengembalikan string kosong bila URL tidak bisa dipakai.
  static String normalizeBaseUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return '';

    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }

    if (uri.path.isEmpty || uri.path == '/') {
      value = '$value/api/v1';
    }

    return value;
  }

  /// Mengubah server API yang dipakai dan menyimpannya di perangkat.
  ///
  /// Dipakai dari layar login supaya aplikasi bisa diarahkan ke backend
  /// mana pun tanpa perlu build ulang.
  Future<bool> setBaseUrl(String raw) async {
    final normalized = normalizeBaseUrl(raw);
    if (normalized.isEmpty) return false;

    await _initPrefs();
    AppConstants.baseUrl = normalized;
    _dio.options.baseUrl = normalized;
    await _prefs?.setString(AppConstants.apiBaseUrlKey, normalized);
    return true;
  }

  /// Mengembalikan server API ke default platform / `--dart-define`.
  Future<void> resetBaseUrl() async {
    await _initPrefs();
    AppConstants.baseUrl = AppConstants.defaultApiBaseUrl;
    _dio.options.baseUrl = AppConstants.baseUrl;
    await _prefs?.remove(AppConstants.apiBaseUrlKey);
  }

  // Token Management
  Future<String?> getToken() async {
    await _initPrefs();
    return _prefs?.getString(AppConstants.tokenKey);
  }

  Future<void> setToken(String token) async {
    await _initPrefs();
    await _prefs?.setString(AppConstants.tokenKey, token);
  }

  Future<void> removeToken() async {
    await _initPrefs();
    await _prefs?.remove(AppConstants.tokenKey);
  }

  // HTTP Methods
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    await _initPrefs();
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String path, {dynamic data}) async {
    await _initPrefs();
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Multipart upload (file uploads). Dio sets the content type together with
  // the boundary whenever `data` is a FormData instance.
  Future<dynamic> postMultipart(String path, FormData data) async {
    await _initPrefs();
    try {
      final response = await _dio.post(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String path, {dynamic data}) async {
    await _initPrefs();
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    await _initPrefs();
    try {
      final response = await _dio.delete(path);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error Handler
  //
  // Pesan sengaja menyertakan URL server yang dipakai: kegagalan login paling
  // sering terjadi karena backend tidak berjalan atau URL API salah.
  String _handleError(DioException error) {
    final target = _dio.options.baseUrl;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi ke server timeout ($target). Periksa jaringan dan pastikan backend berjalan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat HTTPS server tidak valid ($target).';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server ($target). '
            'Pastikan backend berjalan dan URL API benar. '
            'Kalau aplikasi dibuka di browser, server juga harus mengizinkan origin ini (CORS).';
      case DioExceptionType.badResponse:
        return _messageFromResponse(error.response);
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.unknown:
        return 'Tidak bisa menghubungi server ($target). '
            'Periksa koneksi, URL API, dan izin CORS server.';
    }
  }

  String _messageFromResponse(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    if (data is Map) {
      // Laravel mengirim pesan per field pada key `errors`. Untuk login,
      // pesan seperti "Email atau password tidak sesuai" ada di sana.
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        final text = first is List ? (first.isEmpty ? null : first.first) : first;
        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString();
        }
      }

      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return 'Error $statusCode: $message';
      }
    }

    // Balasan HTML (bukan JSON) biasanya berarti URL salah, atau hosting
    // membalas dengan halaman proteksi anti-bot.
    if (data is String && data.trimLeft().startsWith('<')) {
      return 'Server mengembalikan halaman HTML, bukan JSON (Error $statusCode). '
          'Pastikan URL API benar dan hosting tidak memblokir permintaan API.';
    }

    return 'Error $statusCode: permintaan gagal.';
  }
}
