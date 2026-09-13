import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ReviewRepository {
  final ApiService _api;

  ReviewRepository(this._api);

  Map<String, dynamic> _asMap(dynamic response) {
    if (response is Map) return Map<String, dynamic>.from(response);
    return {'success': false, 'data': null};
  }

  /// Create a review. The API requires the booking the review belongs to.
  Future<Map<String, dynamic>> createReview({
    required int studioId,
    int? bookingId,
    required int rating,
    String? comment,
    bool isAnonymous = false,
  }) async {
    return _asMap(await _api.post('/reviews', data: {
      if (bookingId != null) 'booking_id': bookingId,
      'studio_id': studioId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'is_anonymous': isAnonymous,
    }));
  }

  /// Upload review photos
  Future<Map<String, dynamic>> uploadReviewImages(
    int reviewId,
    List<XFile> images,
    List<String> captions,
  ) async {
    final files = <MultipartFile>[];
    for (final image in images) {
      final bytes = await image.readAsBytes();
      files.add(MultipartFile.fromBytes(bytes, filename: image.name));
    }

    final formData = FormData.fromMap({
      'images': files,
      if (captions.isNotEmpty) 'captions': captions,
    });

    return _asMap(await _api.postMultipart('/reviews/$reviewId/images', formData));
  }

  /// Reviews written by the current user
  Future<Map<String, dynamic>> getUserReviews({int page = 1}) async {
    return _asMap(await _api.get(
      '/reviews/my-reviews',
      queryParameters: {'page': page},
    ));
  }

  /// Delete one of the current user's reviews
  Future<void> deleteReview(int reviewId) async {
    await _api.delete('/reviews/$reviewId');
  }
}
