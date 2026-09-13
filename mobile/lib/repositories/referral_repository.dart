import '../services/api_service.dart';

class ReferralRepository {
  final ApiService _api;

  ReferralRepository(this._api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'success': false, 'data': null};
  }

  /// Referral stats, link and credit balance of the current user
  Future<Map<String, dynamic>> getReferralInfo() async {
    return _asMap(await _api.get('/referral'));
  }

  /// Get (or generate) the current user's referral code
  Future<Map<String, dynamic>> getReferralCode() async {
    return _asMap(await _api.get('/referral/code'));
  }

  /// Validate a referral code
  Future<Map<String, dynamic>> validateCode(String code) async {
    return _asMap(await _api.post('/referral/validate', data: {'code': code}));
  }

  /// Top referrers
  Future<Map<String, dynamic>> getLeaderboard() async {
    return _asMap(await _api.get('/referral/leaderboard'));
  }
}
