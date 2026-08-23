<?php

namespace App\Http\Controllers;

use App\Models\Band;
use App\Models\BandMember;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class BandController extends Controller
{
    /**
     * Get user's bands
     */
    public function index(Request $request): JsonResponse
    {
        $bands = Band::where('owner_id', $request->user()->id)
            ->with(['owner:id,name', 'members.user:id,name'])
            ->orderBy('created_at', 'desc')
            ->get();

        // Also get bands where user is a member
        $memberBands = Band::whereHas('members', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id)
                  ->where('status', 'accepted');
        })
        ->with(['owner:id,name', 'members.user:id,name'])
        ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'owned' => $bands->map(function ($band) {
                    return $this->formatBand($band);
                }),
                'member' => $memberBands->map(function ($band) {
                    return $this->formatBand($band);
                }),
            ],
        ]);
    }

    /**
     * Create a new band
     */
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:100',
            'description' => 'nullable|string|max:500',
            'genre' => 'nullable|string|max:50',
            'member_emails' => 'nullable|array',
            'member_emails.*' => 'email|exists:users,email',
        ]);

        $user = $request->user();

        return DB::transaction(function () use ($request, $user) {
            // Create band
            $band = Band::create([
                'owner_id' => $user->id,
                'name' => $request->name,
                'description' => $request->description,
                'genre' => $request->genre,
                'status' => 'active',
            ]);

            // Add owner as member
            BandMember::create([
                'band_id' => $band->id,
                'user_id' => $user->id,
                'role' => 'owner',
                'status' => 'accepted',
            ]);

            // Add invited members
            if ($request->has('member_emails')) {
                foreach ($request->member_emails as $email) {
                    $memberUser = User::where('email', $email)->first();
                    
                    if ($memberUser && $memberUser->id !== $user->id) {
                        BandMember::create([
                            'band_id' => $band->id,
                            'user_id' => $memberUser->id,
                            'role' => 'member',
                            'status' => 'pending',
                        ]);
                    }
                }
            }

            $band->load('members.user:id,name');

            return response()->json([
                'success' => true,
                'message' => 'Band berhasil dibuat',
                'data' => $this->formatBand($band),
            ], 201);
        });
    }

    /**
     * Get band detail
     */
    public function show(Band $band): JsonResponse
    {
        // Check if user is member or owner
        $user = request()->user();
        
        if ($band->owner_id !== $user->id && 
            !$band->members()->where('user_id', $user->id)->exists() &&
            !in_array($user->role, ['admin', 'super_admin'])) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses ke band ini',
            ], 403);
        }

        $band->load('members.user:id,name,email');

        return response()->json([
            'success' => true,
            'data' => $this->formatBand($band),
        ]);
    }

    /**
     * Update band
     */
    public function update(Request $request, Band $band): JsonResponse
    {
        if ($band->owner_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pemilik band yang bisa mengubah data band',
            ], 403);
        }

        $request->validate([
            'name' => 'sometimes|string|max:100',
            'description' => 'nullable|string|max:500',
            'genre' => 'nullable|string|max:50',
        ]);

        $band->update($request->only(['name', 'description', 'genre']));

        return response()->json([
            'success' => true,
            'message' => 'Band berhasil diupdate',
            'data' => $this->formatBand($band->fresh()),
        ]);
    }

    /**
     * Delete band
     */
    public function destroy(Band $band): JsonResponse
    {
        if ($band->owner_id !== request()->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pemilik band yang bisa menghapus band',
            ], 403);
        }

        // Check if band has active bookings
        if ($band->bookings()->whereIn('status', ['pending', 'awaiting_payment', 'confirmed'])->exists()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus band dengan booking aktif',
            ], 422);
        }

        $band->delete();

        return response()->json([
            'success' => true,
            'message' => 'Band berhasil dihapus',
        ]);
    }

    /**
     * Invite member to band
     */
    public function inviteMember(Request $request, Band $band): JsonResponse
    {
        if ($band->owner_id !== $request->user()->id) {
            return response()->json([
                'success' => false,
                'message' => 'Hanya pemilik band yang bisa mengundang anggota',
            ], 403);
        }

        $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $memberUser = User::where('email', $request->email)->first();

        // Check if already a member
        $existingMember = BandMember::where('band_id', $band->id)
            ->where('user_id', $memberUser->id)
            ->first();

        if ($existingMember) {
            return response()->json([
                'success' => false,
                'message' => 'User sudah menjadi anggota band',
            ], 409);
        }

        BandMember::create([
            'band_id' => $band->id,
            'user_id' => $memberUser->id,
            'role' => 'member',
            'status' => 'pending',
        ]);

        // Send notification to invited user
        \App\Models\Notification::create([
            'user_id' => $memberUser->id,
            'type' => 'band_invitation',
            'title' => 'Undangan Band',
            'body' => "{$request->user()->name} mengundang Anda untuk bergabung ke band \"{$band->name}\"",
            'data' => [
                'band_id' => $band->id,
                'band_name' => $band->name,
                'inviter_name' => $request->user()->name,
                'member_id' => null, // Will be set after create
            ],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil dikirim',
        ], 201);
    }

    /**
     * Accept band invitation
     */
    public function acceptInvitation(BandMember $member): JsonResponse
    {
        $user = request()->user();

        if ($member->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk menerima undangan ini',
            ], 403);
        }

        if ($member->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Undangan sudah diproses',
            ], 422);
        }

        $member->update(['status' => 'accepted']);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil diterima',
        ]);
    }

    /**
     * Reject band invitation
     */
    public function rejectInvitation(BandMember $member): JsonResponse
    {
        $user = request()->user();

        if ($member->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk menolak undangan ini',
            ], 403);
        }

        if ($member->status !== 'pending') {
            return response()->json([
                'success' => false,
                'message' => 'Undangan sudah diproses',
            ], 422);
        }

        $member->update(['status' => 'rejected']);

        return response()->json([
            'success' => true,
            'message' => 'Undangan berhasil ditolak',
        ]);
    }

    /**
     * Remove member from band
     */
    public function removeMember(Band $band, BandMember $member): JsonResponse
    {
        $user = request()->user();

        // Only owner can remove members, or member can remove themselves
        if ($band->owner_id !== $user->id && $member->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk menghapus anggota ini',
            ], 403);
        }

        // Cannot remove owner
        if ($member->role === 'owner') {
            return response()->json([
                'success' => false,
                'message' => 'Tidak dapat menghapus pemilik band',
            ], 422);
        }

        $member->delete();

        return response()->json([
            'success' => true,
            'message' => 'Anggota berhasil dihapus dari band',
        ]);
    }

    /**
     * Format band data
     */
    private function formatBand(Band $band): array
    {
        return [
            'id' => $band->id,
            'name' => $band->name,
            'description' => $band->description,
            'genre' => $band->genre,
            'status' => $band->status,
            'owner' => [
                'id' => $band->owner->id,
                'name' => $band->owner->name,
            ],
            'members' => $band->members->map(function ($member) {
                return [
                    'id' => $member->id,
                    'user' => [
                        'id' => $member->user->id,
                        'name' => $member->user->name,
                    ],
                    'role' => $member->role,
                    'status' => $member->status,
                    'joined_at' => $member->accepted_at?->toISOString(),
                ];
            }),
            'created_at' => $band->created_at->toISOString(),
            'updated_at' => $band->updated_at->toISOString(),
        ];
    }
}
