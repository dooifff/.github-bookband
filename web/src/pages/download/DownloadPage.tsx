import { Link } from 'react-router-dom'

/**
 * Halaman unduh aplikasi Android.
 *
 * File APK diletakkan di `public/downloads/studiobook.apk` (atau diarahkan ke
 * URL lain lewat `VITE_APK_URL`), sehingga tombol di bawah menunjuk ke file
 * statis yang sama dengan yang dilayani nginx/hosting.
 */
const APK_URL = import.meta.env.VITE_APK_URL || '/downloads/studiobook.apk'
const APP_VERSION = import.meta.env.VITE_APP_VERSION || '1.0.0'

const steps = [
  {
    title: 'Unduh file APK',
    description: 'Tekan tombol unduh di halaman ini. Browser akan menyimpan file studiobook.apk.',
  },
  {
    title: 'Izinkan instalasi',
    description:
      'Saat diminta, aktifkan "Izinkan dari sumber ini" pada pengaturan keamanan Android kamu.',
  },
  {
    title: 'Pasang aplikasi',
    description: 'Buka file APK dari notifikasi atau folder Download, lalu pilih Install.',
  },
  {
    title: 'Masuk atau daftar',
    description:
      'Buka aplikasi, lalu login dengan akunmu. Belum punya akun? Daftar gratis sebagai customer.',
  },
]

export default function DownloadPage() {
  return (
    <div className="min-h-screen bg-[#050505] relative overflow-hidden">
      {/* Ambient glow */}
      <div className="absolute top-[-15%] right-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(229,62,62,0.08)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

      <div className="relative z-10 max-w-4xl mx-auto px-6 py-16">
        {/* Header */}
        <div className="flex items-center justify-between mb-16">
          <Link to="/" className="inline-block">
            <span
              className="font-black text-3xl tracking-tight text-white"
              style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
            >
              STUDIO<span className="text-[#e53e3e]">BOOK</span>
            </span>
          </Link>
          <Link to="/login" className="btn-red text-sm py-2.5 px-6">
            MASUK
          </Link>
        </div>

        {/* Hero */}
        <div className="text-center mb-14">
          <p className="text-[#e53e3e] text-xs font-semibold tracking-[0.3em] uppercase mb-4">
            APLIKASI ANDROID
          </p>
          <h1
            className="text-white text-4xl md:text-5xl font-black tracking-tight mb-5"
            style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
          >
            DOWNLOAD STUDIOBOOK
          </h1>
          <p className="text-gray-400 text-sm md:text-base max-w-xl mx-auto leading-relaxed">
            Booking studio langsung dari ponsel: cek jadwal kosong, pilih ruangan,
            bayar, dan kelola booking dalam satu aplikasi.
          </p>
        </div>

        {/* Card unduh */}
        <div className="bg-[#0d0d0d] rounded-lg border border-white/5 p-8 md:p-10 mb-14">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-8">
            <div className="flex items-center gap-5">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#c53030] to-[#e53e3e] flex items-center justify-center shrink-0">
                <span className="text-3xl">♫</span>
              </div>
              <div>
                <h2 className="text-white font-bold text-lg">StudioBook Mobile</h2>
                <p className="text-gray-500 text-sm mt-1">
                  Versi {APP_VERSION} • Android 8.0+ • Gratis
                </p>
              </div>
            </div>

            <a
              href={APK_URL}
              download
              className="btn-red text-sm py-4 px-8 text-center shrink-0 inline-flex items-center justify-center gap-2"
            >
              <span>↓</span> UNDUH APK
            </a>
          </div>

          <div className="mt-8 pt-6 border-t border-white/5">
            <p className="text-gray-600 text-xs leading-relaxed">
              Jika tombol di atas menghasilkan halaman tidak ditemukan, file APK belum
              diunggah ke server. Letakkan file di{' '}
              <span className="font-mono text-gray-400">public/downloads/studiobook.apk</span>{' '}
              (atau isi variabel <span className="font-mono text-gray-400">VITE_APK_URL</span>{' '}
              pada file <span className="font-mono text-gray-400">.env</span>).
            </p>
          </div>
        </div>

        {/* Langkah instalasi */}
        <div className="mb-14">
          <h2 className="text-white text-xl font-bold mb-6 tracking-tight">
            Cara Memasang
          </h2>
          <div className="grid sm:grid-cols-2 gap-4">
            {steps.map((step, index) => (
              <div
                key={step.title}
                className="bg-[#0d0d0d] rounded-lg border border-white/5 p-5"
              >
                <div className="flex items-center gap-3 mb-3">
                  <span className="w-7 h-7 rounded-full bg-[#e53e3e]/10 border border-[#e53e3e]/20 text-[#e53e3e] text-xs font-bold flex items-center justify-center">
                    {index + 1}
                  </span>
                  <h3 className="text-white text-sm font-semibold">{step.title}</h3>
                </div>
                <p className="text-gray-500 text-xs leading-relaxed">{step.description}</p>
              </div>
            ))}
          </div>
        </div>

        {/* Alternatif web */}
        <div className="bg-[#0d0d0d] rounded-lg border border-white/5 p-8 text-center">
          <h2 className="text-white font-bold text-lg mb-2">Belum mau memasang aplikasi?</h2>
          <p className="text-gray-500 text-sm mb-6">
            Semua fitur juga tersedia di versi web — tanpa perlu instalasi.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-3">
            <Link to="/register" className="btn-red text-sm py-3 px-6">
              DAFTAR GRATIS
            </Link>
            <Link to="/login" className="btn-glass text-sm py-3 px-6">
              MASUK
            </Link>
          </div>
        </div>

        <div className="mt-12 text-center">
          <Link to="/" className="text-gray-500 text-xs hover:text-[#e53e3e] transition-colors">
            ← Kembali ke Beranda
          </Link>
        </div>
      </div>
    </div>
  )
}
