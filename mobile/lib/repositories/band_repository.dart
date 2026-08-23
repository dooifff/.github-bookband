import '../services/api_service.dart';
import '../models/band_model.dart';

class BandRepository {
  final ApiService _api;

  BandRepository(this._api);

  /// Get user's bands
  Future<Map<String, dynamic>> getBands() async {
    final response = await _api.get('/bands');
    return response['data'];
  }

  /// Create a new band
  Future<BandModel> createBand({
    required String name,
    String? description,
    String? genre,
    List<String>? memberEmails,
  }) async {
    final response = await _api.post('/bands', data: {
      'name': name,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
      if (memberEmails != null) 'member_emails': memberEmails,
    });

    return BandModel.fromJson(response['data']);
  }

  /// Get band detail
  Future<BandModel> getBand(int bandId) async {
    final response = await _api.get('/bands/$bandId');
    return BandModel.fromJson(response['data']);
  }

  /// Update band
  Future<BandModel> updateBand({
    required int bandId,
    String? name,
    String? description,
    String? genre,
  }) async {
    final response = await _api.put('/bands/$bandId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (genre != null) 'genre': genre,
    });

    return BandModel.fromJson(response['data']);
  }

  /// Delete band
  Future<void> deleteBand(int bandId) async {
    await _api.delete('/bands/$bandId');
  }

  /// Invite member to band
  Future<void> inviteMember({
    required int bandId,
    required String email,
  }) async {
    await _api.post('/bands/$bandId/invite', data: {
      'email': email,
    });
  }

  /// Accept invitation
  Future<void> acceptInvitation(int memberId) async {
    await _api.post('/bands/members/$memberId/accept');
  }

  /// Reject invitation
  Future<void> rejectInvitation(int memberId) async {
    await _api.post('/bands/members/$memberId/reject');
  }

  /// Remove member from band
  Future<void> removeMember({
    required int bandId,
    required int memberId,
  }) async {
    await _api.delete('/bands/$bandId/members/$memberId');
  }
}
