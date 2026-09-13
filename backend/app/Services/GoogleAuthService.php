<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;
use RuntimeException;
use Throwable;

class GoogleAuthService
{
    private const JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs';

    private const JWKS_CACHE_KEY = 'google_auth_jwks';

    private const ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    /**
     * Verifikasi Google ID token dan kembalikan claims-nya.
     *
     * @return array<string, mixed>
     */
    public function verifyIdToken(string $idToken): array
    {
        $allowedClientIds = $this->allowedClientIds();

        if (empty($allowedClientIds)) {
            throw ValidationException::withMessages([
                'id_token' => ['Login Google belum dikonfigurasi di server.'],
            ]);
        }

        try {
            $claims = (array) JWT::decode($idToken, JWK::parseKeySet($this->jwks(), 'RS256'));
        } catch (Throwable) {
            throw ValidationException::withMessages([
                'id_token' => ['Token Google tidak valid atau sudah kedaluwarsa.'],
            ]);
        }

        if (! in_array($claims['iss'] ?? '', self::ISSUERS, true)) {
            throw ValidationException::withMessages([
                'id_token' => ['Issuer token Google tidak dikenali.'],
            ]);
        }

        if (! in_array($claims['aud'] ?? '', $allowedClientIds, true)) {
            throw ValidationException::withMessages([
                'id_token' => ['Token Google bukan untuk aplikasi ini.'],
            ]);
        }

        if (empty($claims['sub'])) {
            throw ValidationException::withMessages([
                'id_token' => ['Token Google tidak berisi identitas pengguna.'],
            ]);
        }

        return $claims;
    }

    /**
     * Client ID yang diizinkan (web, Android, iOS).
     *
     * @return array<int, string>
     */
    private function allowedClientIds(): array
    {
        $clientIds = config('services.google.client_ids', []);

        if (! is_array($clientIds)) {
            $clientIds = explode(',', (string) $clientIds);
        }

        return array_values(array_filter(array_map('trim', $clientIds)));
    }

    /**
     * Ambil public key Google (JWKS), di-cache satu jam.
     *
     * @return array<string, mixed>
     */
    private function jwks(): array
    {
        $cached = null;

        try {
            $cached = Cache::get(self::JWKS_CACHE_KEY);
        } catch (Throwable) {
            // Cache store belum siap (mis. tabel cache belum dimigrasi).
        }

        if (is_array($cached) && ! empty($cached['keys'])) {
            return $cached;
        }

        $jwks = $this->fetchJwks();

        try {
            Cache::put(self::JWKS_CACHE_KEY, $jwks, now()->addHour());
        } catch (Throwable) {
            // Gagal menyimpan cache tidak menghalangi proses verifikasi.
        }

        return $jwks;
    }

    /**
     * @return array<string, mixed>
     */
    private function fetchJwks(): array
    {
        $response = Http::timeout(10)->get(self::JWKS_URL);

        if (! $response->successful()) {
            throw new RuntimeException('Gagal mengambil public key Google.');
        }

        $jwks = $response->json();

        if (! is_array($jwks) || empty($jwks['keys'])) {
            throw new RuntimeException('Public key Google tidak valid.');
        }

        return $jwks;
    }
}
