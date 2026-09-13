# Setup Google Sign-In (Register & Login)

Google login sudah terpasang di tiga bagian: **backend (Laravel)**, **website (React)**, dan **mobile (Flutter)**.
Yang perlu Anda lakukan hanya membuat kredensial di Google Cloud Console dan mengisinya ke file env.

## Alur yang dipakai

1. Web (Google Identity Services) / mobile (`google_sign_in`) meminta **ID token** ke Google.
2. ID token dikirim ke backend: `POST /api/v1/auth/google` dengan body `{ "id_token": "..." }`.
3. Backend memverifikasi tanda tangan token (JWKS Google), `iss`, dan `aud` (harus salah satu Client ID di `GOOGLE_CLIENT_IDS`).
4. Backend mencari user berdasarkan `google_id` atau `email`:
   - **Belum ada** → akun baru dibuat otomatis (register). Role default `customer`, atau `owner` bila client mengirim `"role": "owner"`.
   - **Sudah ada** (mis. daftar dulu pakai email/password) → akun otomatis **ditautkan** ke Google.
5. Backend mengembalikan Sanctum token yang sama seperti login biasa: `{ user, token, is_new_user }`.

User yang mendaftar lewat Google tidak punya password lokal, jadi tidak bisa login lewat form password (kolom `users.password` menjadi nullable).

## 1. Buat OAuth Client ID di Google Cloud Console

Buka https://console.cloud.google.com → buat project (atau pakai yang sudah ada).

### a. OAuth consent screen
- User type: **External**.
- Isi nama aplikasi, email support, dan domain.
- Scopes: `openid`, `email`, `profile`.
- Selama status masih **Testing**, tambahkan akun Google Anda sebagai **Test user**, kalau tidak login akan ditolak.

### b. Credentials → Create credentials → OAuth client ID

**Web application** (dipakai website + Android sebagai `serverClientId`)
- Authorized JavaScript origins: `http://localhost:5173` (dev) dan domain produksi Anda.
- Simpan **Client ID** yang berakhiran `apps.googleusercontent.com`.

**Android** (untuk aplikasi mobile)
- Package name harus sama dengan `applicationId` aplikasi Flutter Anda
  (lihat `android/app/build.gradle`; folder `android/` belum ada di repo ini, buat dulu dengan
  `flutter create --platforms=android .` di folder `mobile/`).
- SHA-1 debug keystore:
  ```bash
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
  ```
  Tambahkan juga SHA-1 rilis (dari keystore produksi/Play Console) bila akan dirilis.

**iOS** (opsional, bila akan build iOS)
- Bundle ID harus sama dengan `PRODUCT_BUNDLE_IDENTIFIER` di Xcode.

## 2. Backend — `backend/.env`

```env
# Pisahkan dengan koma. Urutan bebas: web, android, ios.
GOOGLE_CLIENT_IDS=123-abc.apps.googleusercontent.com,456-def.apps.googleusercontent.com
```

Lalu:

```bash
php artisan migrate            # menambah kolom users.google_id, membuat password nullable
php artisan config:clear
```

Catatan: `GOOGLE_CLIENT_IDS` harus memuat **semua** client ID yang dipakai client, karena klaim `aud`
token berbeda per platform (web / Android / iOS). Bila kosong, endpoint mengembalikan 422
"Login Google belum dikonfigurasi di server".

## 3. Website — `web/.env`

```env
VITE_GOOGLE_CLIENT_ID=123-abc.apps.googleusercontent.com
```

Client ID tipe **Web application** yang sama seperti di atas. Setelah itu restart `npm run dev`
(env Vite hanya dibaca saat server start). Bila variabel ini kosong, tombol Google tidak dirender.

## 4. Mobile — `--dart-define`

```bash
cd mobile
flutter run -d edge \
  --dart-define=GOOGLE_WEB_CLIENT_ID=123-abc.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=123-abc.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=456-def.apps.googleusercontent.com
```

- `GOOGLE_WEB_CLIENT_ID` → dipakai saat target web.
- `GOOGLE_SERVER_CLIENT_ID` → **wajib untuk Android**; harus client ID tipe **Web** (bukan Android), karena ID token hanya diterbitkan bila serverClientId diisi.
- `GOOGLE_IOS_CLIENT_ID` → dipakai saat target iOS/macOS.

## 5. Uji cepat

```bash
# Test otomatis backend (tidak memanggil Google, service-nya di-fake)
cd backend && php artisan test --filter=GoogleLoginTest
```

Manual: buka website → `/login` → tombol **Lanjutkan dengan Google** → setelah login, cek
`users.google_id` di database terisi.

## Pemecahan masalah

| Gejala | Penyebab umum |
| --- | --- |
| 422 "Token Google bukan untuk aplikasi ini" | Client ID platform tersebut belum ada di `GOOGLE_CLIENT_IDS` |
| 422 "Token Google tidak valid atau sudah kedaluwarsa" | ID token kedaluwarsa/terpotong, atau `client_id` client tidak cocok dengan project yang sama |
| 422 "Login Google belum dikonfigurasi di server" | `GOOGLE_CLIENT_IDS` masih kosong (lupa `php artisan config:clear`) |
| Tombol Google tidak muncul di web | `VITE_GOOGLE_CLIENT_ID` kosong / dev server belum di-restart |
| Android error "ApiException: 10" | SHA-1 keystore belum didaftarkan di client ID Android |
