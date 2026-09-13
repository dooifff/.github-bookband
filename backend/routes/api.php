<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BookingController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\FavoriteController;
use App\Http\Controllers\ReviewController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\BandController;
use App\Http\Controllers\PromoController;
use App\Http\Controllers\PublicStatsController;
use App\Http\Controllers\BlockedScheduleController;
use App\Http\Controllers\BulkScheduleController;
use App\Http\Controllers\DynamicPricingController;
use App\Http\Controllers\EquipmentController;
use App\Http\Controllers\FacilityController;
use App\Http\Controllers\ReferralController;
use App\Http\Controllers\ChatController;
use App\Http\Controllers\OpeningHourController;
use App\Http\Controllers\RoomController;
use App\Http\Controllers\ScheduleController;
use App\Http\Controllers\StudioController;
use App\Http\Controllers\StudioSubscriptionController;
use App\Http\Controllers\OwnerDashboardController;
use App\Http\Controllers\OwnerAnalyticsController;
use App\Http\Controllers\OwnerRevenueController;
use App\Http\Controllers\AdminDashboardController;
use App\Http\Controllers\AdminUserController;
use App\Http\Controllers\AdminStudioController;
use App\Http\Controllers\AdminBookingController;
use App\Http\Controllers\SubscriberController;
use App\Http\Controllers\OwnerPromoController;
use App\Http\Controllers\PerformanceController;
use App\Http\Controllers\PerformanceAlertController;
use App\Http\Controllers\PerformanceComparisonController;
use App\Http\Controllers\EmailReportController;
use App\Http\Controllers\MetricsController;
use App\Http\Controllers\CacheInvalidationController;
use App\Http\Middleware\CacheControlMiddleware;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes - StudioBook
|--------------------------------------------------------------------------
|
| Base URL: /api/v1
|
| Modules:
|   - Auth (register, login, logout, profile)
|   - Users
|   - Studios
|   - Rooms
|   - Equipment
|   - Schedules
|   - Bookings
|   - Payments
|   - Reviews
|   - Favorites
|   - Promos
|   - Bands
|   - Notifications
|   - Owner Dashboard
|   - Admin Dashboard
|
*/    // Health Check - no cache
Route::get('/health', function () {
    return response()->json([
        'success' => true,
        'message' => 'StudioBook API is running',
        'data' => [
            'version' => '1.0.0',
            'environment' => app()->environment(),
        ],
    ]);
})->middleware('cache.no');

// Debug Route - Check server health (REMOVE AFTER DEBUGGING)
Route::get('/debug', function () {
    $checks = [];

    // PHP Version
    $checks['php_version'] = phpversion();
    $checks['php_ok'] = version_compare(phpversion(), '8.2.0', '>=');

    // APP_KEY
    $checks['app_key_set'] = !empty(config('app.key'));

    // Database connection
    try {
        \Illuminate\Support\Facades\DB::connection()->getPdo();
        $checks['db_connection'] = 'OK';
    } catch (\Exception $e) {
        $checks['db_connection'] = 'FAILED: ' . $e->getMessage();
    }

    // Check tables exist
    try {
        $tables = \Illuminate\Support\Facades\DB::select("SHOW TABLES");
        $tableNames = array_map(function ($t) { return reset($t); }, $tables);
        $checks['tables'] = $tableNames;
        $checks['users_table'] = in_array('users', $tableNames);
        $checks['personal_access_tokens_table'] = in_array('personal_access_tokens', $tableNames);
        $checks['sessions_table'] = in_array('sessions', $tableNames);
        $checks['users_count'] = \Illuminate\Support\Facades\DB::table('users')->count();
    } catch (\Exception $e) {
        $checks['tables_error'] = $e->getMessage();
    }

    // Sanctum config
    $checks['sanctum_stateful_domains'] = config('sanctum.stateful');
    $checks['cors_allowed_origins'] = config('cors.allowed_origins');

    // Session driver
    $checks['session_driver'] = config('session.driver');
    $checks['cache_store'] = config('cache.default');

    return response()->json([
        'success' => true,
        'message' => 'Debug info',
        'data' => $checks,
    ]);
});

// Public Routes (no auth required)
Route::prefix('v1')->group(function () {
    // Auth Routes (Public)
    Route::prefix('auth')->group(function () {
        Route::post('/register', [AuthController::class, 'register']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/google', [AuthController::class, 'google']);
        Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
        Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    });

    // Public Studio Routes (for discovery) - cache 5 min
    Route::prefix('studios')->middleware('cache.public')->group(function () {
        Route::get('/', [StudioController::class, 'index']);
        Route::get('/{slug}', [StudioController::class, 'showBySlug']);
        Route::get('/{slug}/rooms', [RoomController::class, 'index']);
        Route::get('/{slug}/equipment', [EquipmentController::class, 'index']);
        Route::get('/{slug}/opening-hours', [OpeningHourController::class, 'index']);
        Route::get('/{slug}/reviews', [ReviewController::class, 'studioReviews'])->middleware('cache.public:120');
    });

    // Public Schedule Routes (availability check)
    Route::prefix('studios/{slug}')->group(function () {
        Route::get('/availability', [ScheduleController::class, 'checkAvailability']);
        Route::get('/available-slots', [ScheduleController::class, 'getAvailableSlots']);
    });

    // Public Pricing Routes
    Route::post('/pricing/calculate', [DynamicPricingController::class, 'calculatePrice']);
    Route::get('/pricing/preview', [DynamicPricingController::class, 'preview']);

    // Public Promo Routes - cache 5 min
    Route::get('/promos', [PromoController::class, 'index'])->middleware('cache.public');
    Route::get('/promos/{code}', [PromoController::class, 'show'])->middleware('cache.public');

    // Public Platform Stats - cache 5 min
    Route::get('/stats', [PublicStatsController::class, 'index'])->middleware('cache.public');
});

// Protected Routes (auth required)
Route::prefix('v1')->middleware('auth:sanctum')->group(function () {
    // Auth Profile (Protected) - no cache for auth
    Route::prefix('auth')->middleware('cache.no')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::put('/password', [AuthController::class, 'updatePassword']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
    });

    // Bookings
    Route::prefix('bookings')->group(function () {
        Route::get('/', [BookingController::class, 'index']);
        Route::post('/', [BookingController::class, 'store']);
        Route::get('/{booking}', [BookingController::class, 'show']);
        Route::get('/code/{code}', [BookingController::class, 'showByCode']);
        Route::post('/{booking}/cancel', [BookingController::class, 'cancel']);
        Route::get('/{booking}/invoice', [BookingController::class, 'exportInvoice']);
    });

    // Schedule Routes (for studio owners to manage blocked schedules)
    Route::prefix('studios/{studioId}/blocked-schedules')->group(function () {
        Route::get('/', [BlockedScheduleController::class, 'index']);
        Route::post('/', [BlockedScheduleController::class, 'store']);
        Route::put('/{blockedScheduleId}', [BlockedScheduleController::class, 'update']);
        Route::delete('/{blockedScheduleId}', [BlockedScheduleController::class, 'destroy']);
    });

    // Payments
    Route::prefix('payments')->group(function () {
        Route::post('/', [PaymentController::class, 'store']);
        Route::get('/{paymentCode}', [PaymentController::class, 'show']);
        Route::get('/{paymentCode}/status', [PaymentController::class, 'status']);
    });

    // Payment History
    Route::get('/payment-history', [PaymentController::class, 'history']);

    // Favorites
    Route::prefix('favorites')->group(function () {
        Route::get('/', [FavoriteController::class, 'index']);
        Route::post('/', [FavoriteController::class, 'store']);
        Route::post('/toggle', [FavoriteController::class, 'toggle']);
        Route::delete('/{studioId}', [FavoriteController::class, 'destroy']);
        Route::get('/check/{studioId}', [FavoriteController::class, 'check']);
    });

    // Reviews
    Route::prefix('reviews')->group(function () {
        Route::post('/', [ReviewController::class, 'store']);
        Route::get('/my-reviews', [ReviewController::class, 'userReviews']);
        Route::delete('/{review}', [ReviewController::class, 'destroy']);
        Route::post('/{review}/images', [ReviewController::class, 'addImages']);
        Route::delete('/images/{imageId}', [ReviewController::class, 'removeImage']);
    });



    // Bands
    Route::prefix('bands')->group(function () {
        Route::get('/', [BandController::class, 'index']);
        Route::post('/', [BandController::class, 'store']);
        Route::get('/{band}', [BandController::class, 'show']);
        Route::put('/{band}', [BandController::class, 'update']);
        Route::delete('/{band}', [BandController::class, 'destroy']);
        Route::post('/{band}/invite', [BandController::class, 'inviteMember']);
        Route::post('/members/{member}/accept', [BandController::class, 'acceptInvitation']);
        Route::post('/members/{member}/reject', [BandController::class, 'rejectInvitation']);
        Route::delete('/{band}/members/{member}', [BandController::class, 'removeMember']);
    });

    // Referral
    Route::prefix('referral')->group(function () {
        Route::get('/', [ReferralController::class, 'index']);
        Route::get('/code', [ReferralController::class, 'getCode']);
        Route::post('/validate', [ReferralController::class, 'validateCode']);
        Route::get('/leaderboard', [ReferralController::class, 'leaderboard']);
    });

    // Chat
    Route::prefix('chat')->group(function () {
        Route::get('/', [ChatController::class, 'index']);
        Route::post('/rooms', [ChatController::class, 'createRoom']);
        Route::post('/rooms/general', [ChatController::class, 'createGeneralRoom']);
        Route::get('/rooms/{roomId}/messages', [ChatController::class, 'messages']);
        Route::post('/rooms/{roomId}/messages', [ChatController::class, 'sendMessage']);
        Route::post('/rooms/{roomId}/read', [ChatController::class, 'markAsRead']);
        Route::post('/rooms/{roomId}/close', [ChatController::class, 'close']);
        Route::get('/unread-count', [ChatController::class, 'unreadCount']);
    });

    // Notifications
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::post('/{notification}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/read-all', [NotificationController::class, 'markAllAsRead']);
        Route::delete('/{notification}', [NotificationController::class, 'destroy']);
        Route::delete('/', [NotificationController::class, 'destroyAll']);
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
        Route::post('/fcm-token', [NotificationController::class, 'storeFcmToken']);
    });

    // Promos (protected routes only)
    Route::prefix('promos')->group(function () {
        Route::post('/validate', [PromoController::class, 'validateCode']);
    });
});

// Owner Routes (owner role required)
Route::prefix('v1/owner')->middleware(['auth:sanctum', 'role:owner,super_admin'])->group(function () {
    // Studio Management
    Route::get('/studios', [StudioController::class, 'ownerStudios']);
    Route::post('/studios', [StudioController::class, 'store']);
    Route::put('/studios/{id}', [StudioController::class, 'update']);
    Route::delete('/studios/{id}', [StudioController::class, 'destroy']);
    Route::post('/studios/{studioId}/images', [StudioController::class, 'uploadImage']);
    Route::delete('/studios/{studioId}/images/{imageId}', [StudioController::class, 'deleteImage']);

    // Studio Subscription Management (owner)
    Route::get('/studios/{studioId}/subscription', [StudioSubscriptionController::class, 'ownerInfo']);
    Route::post('/studios/{studioId}/subscription/renew', [StudioSubscriptionController::class, 'ownerRenew']);
    
    // Room Management
    Route::get('/studios/{studioId}/rooms', [RoomController::class, 'ownerRooms']);
    Route::post('/studios/{studioId}/rooms', [RoomController::class, 'store']);
    Route::put('/studios/{studioId}/rooms/{roomId}', [RoomController::class, 'update']);
    Route::delete('/studios/{studioId}/rooms/{roomId}', [RoomController::class, 'destroy']);
    
    // Equipment Management
    Route::post('/studios/{studioId}/equipment', [EquipmentController::class, 'store']);
    Route::put('/studios/{studioId}/equipment/{equipmentId}', [EquipmentController::class, 'update']);
    Route::delete('/studios/{studioId}/equipment/{equipmentId}', [EquipmentController::class, 'destroy']);
    
    // Facility Management
    Route::get('/studios/{studioId}/facilities', [FacilityController::class, 'index']);
    Route::post('/studios/{studioId}/facilities', [FacilityController::class, 'store']);
    Route::put('/studios/{studioId}/facilities/{facilityId}', [FacilityController::class, 'update']);
    Route::delete('/studios/{studioId}/facilities/{facilityId}', [FacilityController::class, 'destroy']);
    
    // Opening Hours Management
    Route::put('/studios/{studioId}/opening-hours', [OpeningHourController::class, 'update']);
    
    // Blocked Schedule Management
    Route::get('/studios/{studioId}/blocked-schedules', [BlockedScheduleController::class, 'index']);
    Route::post('/studios/{studioId}/blocked-schedules', [BlockedScheduleController::class, 'store']);
    Route::put('/studios/{studioId}/blocked-schedules/{blockedScheduleId}', [BlockedScheduleController::class, 'update']);
    Route::delete('/studios/{studioId}/blocked-schedules/{blockedScheduleId}', [BlockedScheduleController::class, 'destroy']);
    
    // Bulk Schedule Management
    Route::post('/bulk-schedules/block-dates', [BulkScheduleController::class, 'blockDates']);
    Route::post('/bulk-schedules/block-range', [BulkScheduleController::class, 'blockDateRange']);
    Route::post('/bulk-schedules/block-recurring', [BulkScheduleController::class, 'blockRecurring']);
    Route::post('/bulk-schedules/block-multiple-rooms', [BulkScheduleController::class, 'blockMultipleRooms']);
    Route::post('/bulk-schedules/remove-bulk', [BulkScheduleController::class, 'removeBulk']);
    Route::post('/bulk-schedules/remove-by-range', [BulkScheduleController::class, 'removeByDateRange']);
    Route::get('/bulk-schedules/summary', [BulkScheduleController::class, 'summary']);
    
    // Dynamic Pricing
    Route::get('/pricing-rules', [DynamicPricingController::class, 'index']);
    Route::post('/pricing-rules', [DynamicPricingController::class, 'store']);
    Route::put('/pricing-rules/{id}', [DynamicPricingController::class, 'update']);
    Route::delete('/pricing-rules/{id}', [DynamicPricingController::class, 'destroy']);
    Route::post('/pricing/peak-hour-rules', [DynamicPricingController::class, 'createPeakHourRules']);
    
    // Booking Management
    Route::get('/bookings', [BookingController::class, 'ownerBookings']);
    Route::post('/bookings/{booking}/confirm', [BookingController::class, 'confirm']);
    Route::post('/bookings/{booking}/complete', [BookingController::class, 'complete']);
    
    // Promo Management
    Route::get('/promos', [OwnerPromoController::class, 'index']);
    Route::get('/promos/stats', [OwnerPromoController::class, 'stats']);
    Route::get('/promos/studios', [OwnerPromoController::class, 'studios']);
    Route::get('/promos/generate-code', [OwnerPromoController::class, 'generateCode']);
    Route::get('/promos/{promo}', [OwnerPromoController::class, 'show']);
    Route::post('/promos', [OwnerPromoController::class, 'store']);
    Route::put('/promos/{promo}', [OwnerPromoController::class, 'update']);
    Route::delete('/promos/{promo}', [OwnerPromoController::class, 'destroy']);
    Route::post('/promos/{promo}/toggle', [OwnerPromoController::class, 'toggle']);
    
    // Owner Dashboard & Analytics
    Route::get('/dashboard', [OwnerDashboardController::class, 'index']);
    Route::get('/dashboard/today', [OwnerDashboardController::class, 'todayStats']);
    Route::get('/analytics', [OwnerAnalyticsController::class, 'index']);
    Route::get('/analytics/revenue', [OwnerAnalyticsController::class, 'revenue']);
    Route::get('/analytics/occupancy', [OwnerAnalyticsController::class, 'occupancy']);
    Route::get('/revenue', [OwnerRevenueController::class, 'index']);
    Route::get('/revenue/report', [OwnerRevenueController::class, 'report']);
    Route::get('/revenue/export', [OwnerRevenueController::class, 'export']);
    
    // PDF Export Routes
    Route::get('/revenue/export-pdf', [OwnerRevenueController::class, 'exportPdf']);
    Route::get('/revenue/export-daily-pdf', [OwnerRevenueController::class, 'exportDailyPdf']);
    Route::get('/revenue/export-bookings-pdf', [OwnerRevenueController::class, 'exportBookingsPdf']);
    
    // Excel Export Routes
    Route::get('/revenue/export-excel', [OwnerRevenueController::class, 'exportExcel']);
    Route::get('/revenue/export-bookings-excel', [OwnerRevenueController::class, 'exportBookingsExcel']);
    Route::get('/revenue/export-daily-excel', [OwnerRevenueController::class, 'exportDailyExcel']);
    Route::get('/revenue/export-customers-excel', [OwnerRevenueController::class, 'exportCustomersExcel']);
});

// Payment Webhook Routes (no auth required - webhook from provider)
Route::prefix('v1/payments/webhook')->group(function () {
    Route::post('/midtrans', [PaymentController::class, 'midtransNotification'])->name('payment.webhook.midtrans');
    Route::post('/xendit', [PaymentController::class, 'webhook'])->name('payment.webhook.xendit');
});

// Admin Routes (admin role required)
Route::prefix('v1/admin')->middleware(['auth:sanctum', 'role:admin,super_admin'])->group(function () {
    // Admin Dashboard
    Route::get('/dashboard', [AdminDashboardController::class, 'index']);
    
    // User Management
    Route::post('/users', [AdminUserController::class, 'store']);
    Route::get('/users', [AdminUserController::class, 'index']);
    Route::get('/users/stats', [AdminUserController::class, 'stats']);
    Route::get('/users/{user}', [AdminUserController::class, 'show']);
    Route::put('/users/{user}', [AdminUserController::class, 'update']);
    Route::post('/users/{user}/activate', [AdminUserController::class, 'activate']);
    Route::post('/users/{user}/deactivate', [AdminUserController::class, 'deactivate']);
    
    // Subscriber Management (super admin)
    Route::get('/subscribers', [SubscriberController::class, 'index']);
    Route::get('/subscribers/{subscriber}', [SubscriberController::class, 'show']);
    Route::post('/subscribers/{subscriber}/approve', [SubscriberController::class, 'approve']);
    Route::post('/subscribers/{subscriber}/reject', [SubscriberController::class, 'reject']);
    Route::post('/subscribers/{subscriber}/assign-promo', [SubscriberController::class, 'assignPromo']);
    
    // Studio Management
    Route::get('/studios', [AdminStudioController::class, 'index']);
    Route::get('/studios/stats', [AdminStudioController::class, 'stats']);
    Route::get('/studios/pending', [AdminStudioController::class, 'pendingVerification']);
    Route::get('/studios/{studio}', [AdminStudioController::class, 'show']);
    Route::get('/subscriptions', [StudioSubscriptionController::class, 'adminIndex']);
    Route::get('/subscriptions/{ownerId}', [StudioSubscriptionController::class, 'adminShow']);
    Route::post('/studios/{studio}/subscription', [StudioSubscriptionController::class, 'adminUpdate']);
    Route::post('/studios/{studio}/verify', [AdminStudioController::class, 'verify']);
    Route::post('/studios/{studio}/unverify', [AdminStudioController::class, 'unverify']);
    Route::post('/studios/{studio}/activate', [AdminStudioController::class, 'activate']);
    Route::post('/studios/{studio}/deactivate', [AdminStudioController::class, 'deactivate']);

    // Booking Management
    Route::get('/bookings', [AdminBookingController::class, 'index']);
    Route::get('/bookings/stats', [AdminBookingController::class, 'stats']);
    Route::get('/bookings/{booking}', [AdminBookingController::class, 'show']);
    Route::post('/bookings/{booking}/confirm', [AdminBookingController::class, 'confirm']);
    Route::post('/bookings/{booking}/cancel', [AdminBookingController::class, 'cancel']);


        // Cache Management
        Route::prefix('cache')->group(function () {
            Route::get('/status', [CacheInvalidationController::class, 'status']);
            Route::post('/flush', [CacheInvalidationController::class, 'flushAll']);
            Route::post('/flush/studios', [CacheInvalidationController::class, 'flushStudios']);
            Route::post('/flush/promos', [CacheInvalidationController::class, 'flushPromos']);
            Route::post('/flush/metrics', [CacheInvalidationController::class, 'flushMetrics']);
        });

        // Real-time Metrics
        Route::prefix('metrics')->group(function () {
            Route::get('/', [MetricsController::class, 'overview']);
            Route::get('/routes', [MetricsController::class, 'routes']);
            Route::get('/slow-requests', [MetricsController::class, 'slowRequests']);
            Route::get('/slow-queries', [MetricsController::class, 'slowQueries']);
            Route::get('/database', [MetricsController::class, 'database']);
        });

        // Performance Metrics
        Route::prefix('performance')->group(function () {
            Route::get('/', [PerformanceController::class, 'overview']);
        Route::get('/server', [PerformanceController::class, 'serverMetrics']);
        Route::get('/database', [PerformanceController::class, 'databaseMetrics']);
        Route::get('/api', [PerformanceController::class, 'apiMetrics']);
        Route::get('/realtime', [PerformanceController::class, 'realtime']);
        Route::get('/history', [PerformanceController::class, 'history']);
        
        // Performance Alerts
        Route::prefix('alerts')->group(function () {
            Route::get('/', [PerformanceAlertController::class, 'index']);
            Route::get('/active', [PerformanceAlertController::class, 'active']);
            Route::get('/stats', [PerformanceAlertController::class, 'stats']);
            Route::get('/thresholds', [PerformanceAlertController::class, 'thresholds']);
            Route::put('/thresholds', [PerformanceAlertController::class, 'updateThresholds']);
            Route::post('/check', [PerformanceAlertController::class, 'check']);
            Route::get('/realtime', [PerformanceAlertController::class, 'realtime']);
            Route::delete('/', [PerformanceAlertController::class, 'clear']);
        });
        
        // Performance Comparison & History
        Route::prefix('compare')->group(function () {
            Route::get('/history', [PerformanceComparisonController::class, 'history']);
            Route::post('/', [PerformanceComparisonController::class, 'compare']);
            Route::get('/trend/{metric}', [PerformanceComparisonController::class, 'trend']);
            Route::get('/daily', [PerformanceComparisonController::class, 'dailySummaries']);
            Route::post('/export', [PerformanceComparisonController::class, 'export']);
            Route::post('/snapshot', [PerformanceComparisonController::class, 'storeSnapshot']);
        });
        
        // Email Reports
        Route::prefix('email')->group(function () {
            Route::post('/send', [EmailReportController::class, 'sendReport']);
            Route::post('/weekly', [EmailReportController::class, 'sendWeeklyReport']);
            Route::post('/daily', [EmailReportController::class, 'sendDailySummary']);
            Route::post('/monthly', [EmailReportController::class, 'sendMonthlyReport']);
            Route::post('/regression-alert', [EmailReportController::class, 'sendRegressionAlert']);
            Route::get('/schedule', [EmailReportController::class, 'getScheduleSettings']);
            Route::put('/schedule', [EmailReportController::class, 'updateScheduleSettings']);
        });
    });
});
