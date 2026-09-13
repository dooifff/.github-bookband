<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;

class AdminUserController extends Controller
{
    /**
     * Get all users with filters
     */
    public function index(Request $request): JsonResponse
    {
        $query = User::query();

        // Search filter
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone', 'like', "%{$search}%");
            });
        }

        // Role filter
        if ($request->has('role')) {
            $query->where('role', $request->role);
        }

        // Status filter
        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        $users = $query->orderBy('created_at', 'desc')->paginate(20);

        // Batch load counts to avoid N+1 queries
        $userIds = $users->pluck('id');
        $studiosCounts = \App\Models\Studio::whereIn('owner_id', $userIds)
            ->selectRaw('owner_id, COUNT(*) as cnt')
            ->groupBy('owner_id')
            ->pluck('cnt', 'owner_id');
        $bookingsCounts = \App\Models\Booking::whereIn('user_id', $userIds)
            ->selectRaw('user_id, COUNT(*) as cnt')
            ->groupBy('user_id')
            ->pluck('cnt', 'user_id');

        return response()->json([
            'success' => true,
            'data' => $users->map(fn($user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'is_active' => $user->is_active ?? true,
                'email_verified_at' => $user->email_verified_at?->toISOString(),
                'created_at' => $user->created_at->toISOString(),
                'studios_count' => $studiosCounts->get($user->id, 0),
                'bookings_count' => $bookingsCounts->get($user->id, 0),
            ]),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    /**
     * Get user detail
     */
    public function show(User $user): JsonResponse
    {
        $user->load(['ownedStudios', 'bookings' => function ($q) {
            $q->with(['studio:id,name', 'room:id,name'])
              ->orderBy('created_at', 'desc')
              ->limit(10);
        }]);

        return response()->json([
            'success' => true,
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role,
                'is_active' => $user->is_active,
                'email_verified_at' => $user->email_verified_at?->toISOString(),
                'created_at' => $user->created_at->toISOString(),
                'studios' => $user->ownedStudios->map(fn($studio) => [
                    'id' => $studio->id,
                    'name' => $studio->name,
                    'is_verified' => $studio->is_verified,
                    'is_active' => $studio->is_active,
                ]),
                'bookings' => $user->bookings->map(fn($booking) => [
                    'id' => $booking->id,
                    'booking_code' => $booking->booking_code,
                    'studio' => $booking->studio->name,
                    'room' => $booking->room->name,
                    'date' => $booking->date,
                    'amount' => $booking->total,
                    'status' => $booking->status,
                ]),
                'stats' => [
                    'total_bookings' => $user->bookings()->count(),
                    'total_spent' => $user->bookings()->where('status', 'completed')->sum('total'),
                ],
            ],
        ]);
    }

    /**
     * Update user (role, status)
     */
    public function update(Request $request, User $user): JsonResponse
    {
        $request->validate([
            'role' => 'sometimes|in:customer,owner,admin,super_admin',
            'is_active' => 'sometimes|boolean',
        ]);

        // Prevent modifying super_admin
        if ($user->role === 'super_admin' && $request->user()->role !== 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat mengubah super admin',
            ], 403);
        }

        $user->update($request->only(['role', 'is_active']));

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diupdate',
            'data' => [
                'id' => $user->id,
                'role' => $user->role,
                'is_active' => $user->is_active,
            ],
        ]);
    }

    /**
     * Deactivate user
     */
    public function deactivate(User $user): JsonResponse
    {
        if ($user->role === 'super_admin') {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menonaktifkan super admin',
            ], 403);
        }

        $user->update(['is_active' => false]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil dinonaktifkan',
        ]);
    }

    /**
     * Activate user
     */
    public function activate(User $user): JsonResponse
    {
        $user->update(['is_active' => true]);

        return response()->json([
            'success' => true,
            'message' => 'User berhasil diaktifkan',
        ]);
    }

    /**
     * Create a new owner account
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'phone' => 'nullable|string|max:20',
            'password' => 'required|string|min:8',
            'role' => 'sometimes|in:owner,admin,customer',
        ]);

        $user = \App\Models\User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'phone' => $validated['phone'] ?? null,
            'role' => $validated['role'] ?? 'owner',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Akun berhasil dibuat',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
            ],
        ], 201);
    }

    /**
     * Get user statistics
     */
    public function stats(): JsonResponse
    {
        $totalUsers = User::count();
        $byRole = User::selectRaw('role, COUNT(*) as count')
            ->groupBy('role')
            ->pluck('count', 'role');

        $recentRegistrations = User::where('created_at', '>=', now()->subDays(30))
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'total' => $totalUsers,
                'by_role' => $byRole,
                'recent_registrations' => $recentRegistrations,
            ],
        ]);
    }
}
