<?php

namespace App\Http\Controllers;

use App\Http\Requests\ForgotPasswordRequest;
use App\Http\Requests\GoogleAuthRequest;
use App\Http\Requests\LoginRequest;
use App\Http\Requests\RegisterRequest;
use App\Http\Requests\ResetPasswordRequest;
use App\Http\Requests\UpdatePasswordRequest;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\GoogleAuthService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    /**
     * Register new user
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'phone' => $request->phone,
            'role' => 'customer',
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Registrasi berhasil', 201);
    }

    /**
     * Login user
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Email atau password tidak sesuai'],
            ]);
        }

        // Revoke previous tokens (optional - for single session)
        // $user->tokens()->delete();

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
        ], 'Login berhasil');
    }

    /**
     * Login/register with Google (ID token dari Google Identity Services)
     */
    public function google(GoogleAuthRequest $request, GoogleAuthService $googleAuth): JsonResponse
    {
        $claims = $googleAuth->verifyIdToken($request->string('id_token')->toString());

        $googleId = (string) $claims['sub'];
        $email = $claims['email'] ?? null;

        if (! $email) {
            throw ValidationException::withMessages([
                'id_token' => ['Akun Google tidak mengirimkan email'],
            ]);
        }

        if (($claims['email_verified'] ?? false) !== true) {
            throw ValidationException::withMessages([
                'id_token' => ['Email Google belum terverifikasi'],
            ]);
        }

        $user = User::where('google_id', $googleId)
            ->orWhere('email', $email)
            ->first();

        $isNewUser = false;

        if ($user) {
            $attributes = [];

            // Tautkan akun lama (yang mendaftar dengan email/password) ke Google.
            if (! $user->google_id) {
                $attributes['google_id'] = $googleId;
            }

            if (! $user->avatar && ! empty($claims['picture'])) {
                $attributes['avatar'] = $claims['picture'];
            }

            if (! $user->email_verified_at) {
                $attributes['email_verified_at'] = now();
            }

            if ($attributes) {
                $user->forceFill($attributes)->save();
            }
        } else {
            $isNewUser = true;

            $user = User::create([
                'name' => $claims['name'] ?? Str::before($email, '@'),
                'email' => $email,
                'google_id' => $googleId,
                'avatar' => $claims['picture'] ?? null,
                'role' => $request->input('role') === 'owner' ? 'owner' : 'customer',
                'email_verified_at' => now(),
            ]);
        }

        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'user' => new UserResource($user),
            'token' => $token,
            'is_new_user' => $isNewUser,
        ], $isNewUser ? 'Registrasi berhasil' : 'Login berhasil', $isNewUser ? 201 : 200);
    }

    /**
     * Logout user (revoke current token)
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->successResponse(null, 'Logout berhasil');
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        return $this->successResponse(
            new UserResource($request->user()),
            'Profil berhasil diambil'
        );
    }

    /**
     * Update user profile
     */
    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $request->user();
        
        $data = $request->only(['name', 'email', 'phone', 'avatar']);
        
        // Only update non-null values
        $data = array_filter($data, fn($value) => $value !== null);
        
        $user->update($data);

        return $this->successResponse(
            new UserResource($user->fresh()),
            'Profil berhasil diperbarui'
        );
    }

    /**
     * Update user password
     */
    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $user = $request->user();
        
        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Revoke all other tokens (optional)
        // $user->tokens()->where('id', '!=', $user->currentAccessToken()->id)->delete();

        return $this->successResponse(null, 'Password berhasil diperbarui');
    }

    /**
     * Send forgot password email
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $status = Password::sendResetLink(
            $request->only('email')
        );

        // Selalu balas sukses agar tidak membocorkan email mana yang terdaftar.
        if (in_array($status, [Password::RESET_LINK_SENT, Password::INVALID_USER], true)) {
            return $this->successResponse(null, 'Link reset password telah dikirim ke email');
        }

        return $this->errorResponse(
            $status === Password::RESET_THROTTLED
                ? 'Mohon tunggu sebelum meminta link reset lagi'
                : 'Gagal mengirim link reset password',
            429
        );
    }

    /**
     * Reset password with token
     */
    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill([
                    'password' => Hash::make($password),
                    'remember_token' => Str::random(60),
                ])->save();
            }
        );

        if ($status === Password::PASSWORD_RESET) {
            return $this->successResponse(null, 'Password berhasil direset');
        }

        return $this->errorResponse('Token reset tidak valid atau sudah kedaluwarsa', 422);
    }

    /**
     * Refresh token (get new token)
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        
        // Delete current token
        $request->user()->currentAccessToken()->delete();
        
        // Create new token
        $token = $user->createToken('auth-token')->plainTextToken;

        return $this->successResponse([
            'token' => $token,
        ], 'Token berhasil direfresh');
    }
}
