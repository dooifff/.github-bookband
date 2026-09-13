# Folder unduhan (APK Android)

Letakkan file APK rilis di sini dengan nama:

```
web/public/downloads/studiobook.apk
```

Setelah itu halaman `/download` akan melayani file tersebut (tombol **UNDUH APK**).

## Cara membuat APK

Folder `mobile/` belum memiliki platform Android. Untuk membuat APK:

```bash
# sekali saja: tambahkan platform Android
cd mobile
flutter create --platforms=android .

# build APK rilis
flutter build apk --release
```

Hasil build ada di `mobile/build/app/outputs/flutter-apk/app-release.apk`.
Salin file itu ke `web/public/downloads/studiobook.apk`.

## Alternatif

Jika APK disimpan di tempat lain (mis. GitHub Releases atau object storage),
arahkan lewat variabel lingkungan pada `web/.env`:

```
VITE_APK_URL=https://contoh.com/path/studiobook.apk
```
