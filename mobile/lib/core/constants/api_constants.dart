class ApiConstants {
  // Base URLs
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  
  // Full base URL
  static const String apiUrl = '$baseUrl$apiVersion';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String profile = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String updatePassword = '/auth/password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String refreshToken = '/auth/refresh';

  // Studio endpoints
  static const String studios = '/studios';
  static String studioBySlug(String slug) => '/studios/$slug';
  static String studioRooms(String slug) => '/studios/$slug/rooms';
  static String studioEquipment(String slug) => '/studios/$slug/equipment';
  static String studioOpeningHours(String slug) => '/studios/$slug/opening-hours';
  static String studioAvailability(String slug) => '/studios/$slug/availability';
  static String studioAvailableSlots(String slug) => '/studios/$slug/available-slots';
  static String studioReviews(String slug) => '/studios/$slug/reviews';

  // Booking endpoints
  static const String bookings = '/bookings';
  static String bookingDetail(int id) => '/bookings/$id';
  static String bookingByCode(String code) => '/bookings/code/$code';
  static String cancelBooking(int id) => '/bookings/$id/cancel';

  // Payment endpoints
  static const String payments = '/payments';
  static String paymentDetail(String code) => '/payments/$code';
  static String paymentStatus(String code) => '/payments/$code/status';
  static const String paymentHistory = '/payment-history';
  static String paymentWebhook(String provider) => '/payments/webhook/$provider';

  // Favorite endpoints
  static const String favorites = '/favorites';
  static String favoriteCheck(int studioId) => '/favorites/check/$studioId';
  static String favoriteToggle = '/favorites/toggle';

  // Review endpoints
  static const String reviews = '/reviews';
  static const String myReviews = '/reviews/my-reviews';

  // Band endpoints
  static const String bands = '/bands';
  static String bandDetail(int id) => '/bands/$id';
  static String bandInvite(int id) => '/bands/$id/invite';
  static String bandMemberAction(int memberId, String action) => '/bands/members/$memberId/$action';
  static String bandRemoveMember(int bandId, int memberId) => '/bands/$bandId/members/$memberId';

  // Notification endpoints
  static const String notifications = '/notifications';
  static String notificationRead(int id) => '/notifications/$id/read';
  static const String notificationsReadAll = '/notifications/read-all';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsFcmToken = '/notifications/fcm-token';

  // Promo endpoints
  static const String promos = '/promos';
  static const String promoValidate = '/promos/validate';
  static String promoDetail(String code) => '/promos/$code';

  // Owner endpoints
  static const String ownerStudios = '/owner/studios';
  static String ownerStudioDetail(int id) => '/owner/studios/$id';
  static String ownerStudioRooms(int studioId) => '/owner/studios/$studioId/rooms';
  static String ownerStudioEquipment(int studioId) => '/owner/studios/$studioId/equipment';
  static String ownerStudioOpeningHours(int studioId) => '/owner/studios/$studioId/opening-hours';
  static String ownerStudioBlockedSchedules(int studioId) => '/owner/studios/$studioId/blocked-schedules';
  static const String ownerBookings = '/owner/bookings';
  static String ownerBookingConfirm(int id) => '/owner/bookings/$id/confirm';
  static String ownerBookingComplete(int id) => '/owner/bookings/$id/complete';
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerDashboardToday = '/owner/dashboard/today';
  static const String ownerAnalytics = '/owner/analytics';
  static const String ownerAnalyticsRevenue = '/owner/analytics/revenue';
  static const String ownerAnalyticsOccupancy = '/owner/analytics/occupancy';
  static const String ownerRevenue = '/owner/revenue';
  static const String ownerRevenueReport = '/owner/revenue/report';
  static const String ownerRevenueExport = '/owner/revenue/export';

  // Admin endpoints
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminUserStats = '/admin/users/stats';
  static String adminUserDetail(int id) => '/admin/users/$id';
  static String adminUserActivate(int id) => '/admin/users/$id/activate';
  static String adminUserDeactivate(int id) => '/admin/users/$id/deactivate';
  static const String adminStudios = '/admin/studios';
  static const String adminStudioStats = '/admin/studios/stats';
  static const String adminStudioPending = '/admin/studios/pending';
  static String adminStudioDetail(int id) => '/admin/studios/$id';
  static String adminStudioVerify(int id) => '/admin/studios/$id/verify';
  static String adminStudioUnverify(int id) => '/admin/studios/$id/unverify';
  static String adminStudioActivate(int id) => '/admin/studios/$id/activate';
  static String adminStudioDeactivate(int id) => '/admin/studios/$id/deactivate';

  // Timeouts
  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;
}
