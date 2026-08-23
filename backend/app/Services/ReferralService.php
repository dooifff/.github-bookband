<?php

namespace App\Services;

use App\Models\User;
use App\Models\Referral;
use App\Models\ReferralReward;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ReferralService
{
    /**
     * Generate unique referral code for user
     */
    public function generateReferralCode(User $user): string
    {
        // Check if user already has a code
        $existing = Referral::where('referrer_id', $user->id)->first();
        if ($existing) {
            return $existing->code;
        }

        // Generate unique code
        do {
            $code = strtoupper(Str::random(8));
        } while (Referral::where('code', $code)->exists());

        // Create referral record
        Referral::create([
            'referrer_id' => $user->id,
            'code' => $code,
            'is_active' => true,
        ]);

        return $code;
    }

    /**
     * Apply referral code during registration
     */
    public function applyReferralCode(User $newUser, string $code): bool
    {
        $referral = Referral::where('code', $code)
            ->where('is_active', true)
            ->first();

        if (!$referral) {
            throw new \Exception('Kode referral tidak valid atau sudah tidak aktif');
        }

        // Can't refer yourself
        if ($referral->referrer_id === $newUser->id) {
            throw new \Exception('Tidak bisa menggunakan kode referral sendiri');
        }

        // Check if already used this referrer
        $alreadyUsed = Referral::where('referrer_id', $referral->referrer_id)
            ->where('referred_id', $newUser->id)
            ->exists();

        if ($alreadyUsed) {
            throw new \Exception('Anda sudah menggunakan kode referral dari pengguna ini');
        }

        DB::beginTransaction();

        try {
            // Update referral record
            $referral->update([
                'referred_id' => $newUser->id,
                'referred_at' => now(),
            ]);

            // Update new user
            $newUser->update([
                'referred_by' => $referral->referrer_id,
                'referral_code_used' => $code,
            ]);

            // Give reward to referrer
            $this->giveReferrerReward($referral->referrer_id, $newUser->id);

            // Give reward to new user
            $this->giveNewUserReward($newUser->id, $referral->referrer_id);

            DB::commit();
            return true;
        } catch (\Exception $e) {
            DB::rollBack();
            throw $e;
        }
    }

    /**
     * Give reward to referrer
     */
    protected function giveReferrerReward(int $referrerId, int $referredId): void
    {
        $reward = ReferralReward::where('type', 'referrer')->first();

        if ($reward) {
            $user = User::findOrFail($referrerId);
            
            // Add credit/discount
            $user->increment('referral_credits', $reward->amount);

            // Create notification
            $user->notify(new \App\Notifications\ReferralRewardNotification(
                'referral_success',
                "Anda mendapat reward Rp {$reward->amount} dari referral!",
                $referredId
            ));
        }
    }

    /**
     * Give reward to new user
     */
    protected function giveNewUserReward(int $newUserId, int $referrerId): void
    {
        $reward = ReferralReward::where('type', 'new_user')->first();

        if ($reward) {
            $user = User::findOrFail($newUserId);
            
            // Add welcome bonus
            $user->increment('referral_credits', $reward->amount);
        }
    }

    /**
     * Get referral stats for user
     */
    public function getReferralStats(int $userId): array
    {
        $referral = Referral::where('referrer_id', $userId)->first();

        if (!$referral) {
            return [
                'code' => null,
                'total_referrals' => 0,
                'total_earned' => 0,
                'pending_earned' => 0,
                'referred_users' => [],
            ];
        }

        $referredUsers = User::where('referred_by', $userId)
            ->select('id', 'name', 'email', 'created_at')
            ->get();

        return [
            'code' => $referral->code,
            'total_referrals' => $referredUsers->count(),
            'total_earned' => $referral->total_earned ?? 0,
            'pending_earned' => $referral->pending_earned ?? 0,
            'referred_users' => $referredUsers,
        ];
    }

    /**
     * Get referral link
     */
    public function getReferralLink(int $userId): string
    {
        $referral = Referral::where('referrer_id', $userId)->first();

        if (!$referral) {
            $code = $this->generateReferralCode(User::findOrFail($userId));
        } else {
            $code = $referral->code;
        }

        return url("/register?ref={$code}");
    }

    /**
     * Validate referral code
     */
    public function validateCode(string $code): bool
    {
        return Referral::where('code', $code)
            ->where('is_active', true)
            ->exists();
    }

    /**
     * Get top referrers
     */
    public function getTopReferrers(int $limit = 10): array
    {
        return User::select('id', 'name', 'email')
            ->withCount('referrals')
            ->orderByDesc('referrals_count')
            ->limit($limit)
            ->get()
            ->map(function ($user) {
                return [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'total_referrals' => $user->referrals_count,
                ];
            })
            ->toArray();
    }
}
