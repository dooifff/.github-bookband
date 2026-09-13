import 'package:flutter_test/flutter_test.dart';

import 'package:studiobook/core/constants/app_constants.dart';
import 'package:studiobook/services/api_service.dart';

void main() {
  group('ApiService.normalizeBaseUrl', () {
    test('menambahkan skema http bila belum ada', () {
      expect(
        ApiService.normalizeBaseUrl('192.168.1.10:8000'),
        'http://192.168.1.10:8000/api/v1',
      );
    });

    test('menambahkan /api/v1 bila hanya domain', () {
      expect(
        ApiService.normalizeBaseUrl('https://contoh.com'),
        'https://contoh.com/api/v1',
      );
      expect(
        ApiService.normalizeBaseUrl('https://contoh.com/'),
        'https://contoh.com/api/v1',
      );
    });

    test('membiarkan path /api/v1 yang sudah ditulis', () {
      expect(
        ApiService.normalizeBaseUrl('https://contoh.com/api/v1'),
        'https://contoh.com/api/v1',
      );
      expect(
        ApiService.normalizeBaseUrl('  http://localhost:8000/api/v1/  '),
        'http://localhost:8000/api/v1',
      );
    });

    test('menolak input kosong atau tanpa host', () {
      expect(ApiService.normalizeBaseUrl(''), '');
      expect(ApiService.normalizeBaseUrl('   '), '');
      expect(ApiService.normalizeBaseUrl('http://'), '');
    });
  });

  test('default base URL selalu menunjuk ke endpoint /api/v1', () {
    expect(AppConstants.defaultApiBaseUrl, endsWith('/api/v1'));
    expect(AppConstants.baseUrl, AppConstants.defaultApiBaseUrl);
  });
}
