# StudioBook Mobile (Flutter)

Aplikasi Flutter untuk customer & owner. Saat ini satu-satunya platform yang
tersedia di repo ini adalah **web** (`flutter run -d chrome`).

## Menjalankan

```bash
cd mobile
flutter pub get
flutter run -d chrome
```

## Menghubungkan ke backend

Alamat API diambil dengan urutan prioritas berikut:

1. `--dart-define=API_BASE_URL=...` saat build/run
2. Nilai yang diisi dari layar login (**tombol "Server: ..."** di bawah kolom
   password) — disimpan di perangkat, jadi bisa diganti tanpa build ulang
3. Default per platform

| Platform | Default |
|---|---|
| Web / iOS simulator | `http://localhost:8000/api/v1` |
| Emulator Android | `http://10.0.2.2:8000/api/v1` |

Contoh:

```bash
# Backend di komputer, diakses dari emulator Android (default sudah 10.0.2.2)
flutter run -d emulator-5554

# Backend di komputer, diakses dari HP fisik (samakan dengan IP komputer)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api/v1

# Backend yang sudah dideploy
flutter run -d chrome --dart-define=API_BASE_URL=https://domain-anda.com/api/v1
```

### Menjalankan backend lokal

Backend butuh **PHP >= 8.2** (Laravel 11). Kalau `php -v` masih 8.1:

```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

`--host=0.0.0.0` diperlukan agar HP/emulator bisa mengakses backend.

### Catatan CORS

Kalau aplikasi dibuka di **browser** (Flutter web), backend harus mengizinkan
origin aplikasi. `backend/config/cors.php` sudah mengizinkan `localhost` pada
port berapa pun selama `APP_ENV` bukan `production`, sehingga `flutter run -d
chrome` (port acak) bisa login.

## Akun demo

| Role | Email | Password |
|---|---|---|
| Super Admin | `admin@studiobook.com` | `password` |
| Owner | `owner@studiobook.com` | `password` |
| Customer | `customer@studiobook.com` | `password` |

## Test

```bash
flutter test
flutter analyze
```
