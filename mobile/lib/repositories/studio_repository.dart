import '../services/api_service.dart';
import '../models/studio_model.dart';

class StudioRepository {
  final ApiService _api;

  StudioRepository(this._api);

  /// Get list of studios with filters
  Future<Map<String, dynamic>> getStudios({
    String? search,
    String? city,
    String? province,
    double? minRating,
    double? maxPrice,
    double? minPrice,
    String? sortBy,
    int page = 1,
    int limit = 15,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null) queryParams['search'] = search;
    if (city != null) queryParams['city'] = city;
    if (province != null) queryParams['province'] = province;
    if (minRating != null) queryParams['min_rating'] = minRating;
    if (maxPrice != null) queryParams['max_price'] = maxPrice;
    if (minPrice != null) queryParams['min_price'] = minPrice;
    if (sortBy != null) queryParams['sort_by'] = sortBy;

    final response = await _api.get('/studios', queryParameters: queryParams);

    return {
      'studios': (response['data'] as List)
          .map((json) => Studio.fromJson(json))
          .toList(),
      'meta': response['meta'],
    };
  }

  /// Get studio detail by slug
  Future<Studio> getStudioBySlug(String slug) async {
    final response = await _api.get('/studios/$slug');
    return Studio.fromJson(response['data']);
  }

  /// Get studio rooms
  Future<List<Map<String, dynamic>>> getStudioRooms(String slug) async {
    final response = await _api.get('/studios/$slug/rooms');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Get studio equipment
  Future<List<Map<String, dynamic>>> getStudioEquipment(String slug) async {
    final response = await _api.get('/studios/$slug/equipment');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Get studio opening hours
  Future<List<Map<String, dynamic>>> getOpeningHours(String slug) async {
    final response = await _api.get('/studios/$slug/opening-hours');
    return List<Map<String, dynamic>>.from(response['data']);
  }

  /// Check availability
  Future<Map<String, dynamic>> checkAvailability({
    required String slug,
    required String date,
    required String roomId,
  }) async {
    final response = await _api.get(
      '/studios/$slug/availability',
      queryParameters: {
        'date': date,
        'room_id': roomId,
      },
    );
    return response['data'];
  }

  /// Get available time slots
  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required String slug,
    required String date,
    required String roomId,
  }) async {
    final response = await _api.get(
      '/studios/$slug/available-slots',
      queryParameters: {
        'date': date,
        'room_id': roomId,
      },
    );
    final data = response['data'];
    if (data is Map) {
      final slots = data['slots'];
      if (slots is List) {
        return List<Map<String, dynamic>>.from(slots);
      }
    }
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  /// Dynamic pricing preview for a room over a date range
  Future<Map<String, dynamic>> getPricingPreview(
    int roomId,
    String startDate,
    String endDate, {
    String? startTime,
    String? endTime,
  }) async {
    final response = await _api.get('/pricing/preview', queryParameters: {
      'room_id': roomId,
      'start_date': startDate,
      'end_date': endDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
    });

    final data = response['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      map['pricing'] ??= const [];
      return map;
    }
    if (data is List) {
      return {'pricing': data};
    }
    return {'pricing': const []};
  }

  /// Get studio reviews
  Future<Map<String, dynamic>> getStudioReviews(
    String slug, {
    int page = 1,
  }) async {
    final response = await _api.get(
      '/studios/$slug/reviews',
      queryParameters: {'page': page},
    );
    return {
      'reviews': response['data'],
      'meta': response['meta'],
      'summary': response['summary'],
    };
  }

  /// Toggle favorite
  Future<bool> toggleFavorite(int studioId) async {
    final response = await _api.post('/favorites/toggle', data: {
      'studio_id': studioId,
    });
    return response['data']['is_favorited'];
  }

  /// Check if studio is favorited
  Future<bool> checkFavorite(int studioId) async {
    final response = await _api.get('/favorites/check/$studioId');
    return response['data']['is_favorited'];
  }

  /// Get user favorites
  Future<Map<String, dynamic>> getFavorites({int page = 1}) async {
    final response = await _api.get('/favorites', queryParameters: {'page': page});
    return {
      'favorites': response['data'],
      'meta': response['meta'],
    };
  }

  /// Block multiple dates for a room
  Future<Map<String, dynamic>> blockDates(
    int roomId,
    List<String> dates, {
    String? reason,
  }) async {
    final response = await _api.post('/owner/bulk-schedules/block-dates', data: {
      'room_id': roomId,
      'dates': dates,
      if (reason != null) 'reason': reason,
    });
    return response;
  }

  /// Block date range for a room
  Future<Map<String, dynamic>> blockDateRange(
    int roomId,
    String startDate,
    String endDate, {
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final response = await _api.post('/owner/bulk-schedules/block-range', data: {
      'room_id': roomId,
      'start_date': startDate,
      'end_date': endDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (reason != null) 'reason': reason,
    });
    return response;
  }

  /// Block recurring schedule (weekly)
  Future<Map<String, dynamic>> blockRecurring(
    int roomId,
    List<int> daysOfWeek,
    String startDate,
    String endDate, {
    String? startTime,
    String? endTime,
    String? reason,
  }) async {
    final response = await _api.post('/owner/bulk-schedules/block-recurring', data: {
      'room_id': roomId,
      'days_of_week': daysOfWeek,
      'start_date': startDate,
      'end_date': endDate,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (reason != null) 'reason': reason,
    });
    return response;
  }

  /// Block multiple rooms for same dates
  Future<Map<String, dynamic>> blockMultipleRooms(
    List<int> roomIds,
    List<String> dates, {
    String? reason,
  }) async {
    final response = await _api.post('/owner/bulk-schedules/block-multiple-rooms', data: {
      'room_ids': roomIds,
      'dates': dates,
      if (reason != null) 'reason': reason,
    });
    return response;
  }

  /// Remove blocked schedules in bulk
  Future<Map<String, dynamic>> removeBulkBlocked(List<int> blockedIds) async {
    final response = await _api.post('/owner/bulk-schedules/remove-bulk', data: {
      'blocked_ids': blockedIds,
    });
    return response;
  }

  /// Get blocked schedules summary
  Future<Map<String, dynamic>> getBlockedSummary(
    int roomId,
    String startDate,
    String endDate,
  ) async {
    final response = await _api.get('/owner/bulk-schedules/summary', queryParameters: {
      'room_id': roomId,
      'start_date': startDate,
      'end_date': endDate,
    });
    return response['data'];
  }
}
