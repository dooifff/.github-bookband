import { Link } from 'react-router-dom'
import { useState, useEffect } from 'react'

const features = [
  {
    icon: '🎵',
    title: 'Studio Premium',
    description: 'Akses studio musik kelas atas dengan peralatan profesional dan ruangan yang diawasi akustiknya.'
  },
  {
    icon: '📅',
    title: 'Pemesanan Mudah',
    description: 'Pesan waktu studio favorit Anda dalam hitungan detik dengan sistem penjadwalan kami yang intuitif.'
  },
  {
    icon: '⚡',
    title: 'Konfirmasi Instan',
    description: 'Dapatkan konfirmasi pemesanan segera dan pembaruan status secara real-time.'
  },
  {
    icon: '💳',
    title: 'Pembayaran Aman',
    description: 'Berbagai opsi pembayaran dengan enkripsi tingkat bank untuk transaksi yang aman dan mudah.'
  },
  {
    icon: '⭐',
    title: 'Ulasan Terverifikasi',
    description: 'Baca ulasan autentik dari musisi lain untuk menemukan studio yang sempurna untuk kebutuhan Anda.'
  },
  {
    icon: '📱',
    title: 'Ramah Seluler',
    description: 'Kelola pemesanan Anda di mana saja dengan platform responsif kami yang bekerja di semua perangkat.'
  },
]

const stats = [
  { value: '500+', label: 'Studio' },
  { value: '10K+', label: 'Pemesanan' },
  { value: '4.9', label: 'Penilaian' },
  { value: '50+', label: 'Kota' },
]

const testimonials = [
  {
    name: 'Rizky Pratama',
    role: 'Artis Independen',
    quote: 'StudioBook membuat pencarian studio sempurna menjadi sangat mudah. Proses pemesanannya mulus dan studio-studionya luar biasa.',
    rating: 5,
  },
  {
    name: 'Anisa Dewi',
    role: 'Produser Musik',
    quote: 'Sebagai produser, saya membutuhkan studio yang andal. StudioBook selalu memberikan opsi berkualitas dengan harga yang transparan.',
    rating: 5,
  },
  {
    name: 'Budi Santoso',
    role: 'Pemilik Studio',
    quote: 'Sejak bergabung dengan StudioBook, pemesanan studio saya meningkat 40%. Platform ini mengubah permainan bagi pemilik studio.',
    rating: 5,
  },
]

export default function LandingPage() {
  const [scrollY, setScrollY] = useState(0)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const isScrolled = scrollY > 50

  return (
    <div className="min-h-screen bg-primary text-text-primary overflow-x-hidden">
      {/* ═══ Navigation ═══ */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        isScrolled ? 'glass-strong py-3' : 'py-5 bg-transparent'
      }`}>
        <div className="max-w-7xl mx-auto px-6 flex items-center justify-between">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-2.5 group">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-accent/25 to-accent/5 flex items-center justify-center border border-accent/10 group-hover:border-accent/25 transition-all">
              <span className="text-sm">🎸</span>
            </div>
            <span className="gold-text-static font-bold text-lg tracking-tight">StudioBook</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-text-secondary text-sm hover:text-text-primary transition-colors">Fitur</a>
            <a href="#stats" className="text-text-secondary text-sm hover:text-text-primary transition-colors">Tentang</a>
            <a href="#testimonials" className="text-text-secondary text-sm hover:text-text-primary transition-colors">Testimoni</a>
          </div>

          {/* CTA */}
          <div className="hidden md:flex items-center gap-3">
            <Link to="/login" className="btn-glass text-sm py-2 px-5">Masuk</Link>
            <Link to="/login" className="btn-gold text-sm py-2 px-5">Mulai Sekarang</Link>
          </div>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden text-text-secondary hover:text-text-primary transition-colors p-2"
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              {mobileMenuOpen ? (
                <path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" />
              ) : (
                <path d="M4 6h16M4 12h16M4 18h16" strokeLinecap="round" />
              )}
            </svg>
          </button>
        </div>

        {/* Mobile menu */}
        {mobileMenuOpen && (
          <div className="md:hidden glass-strong mt-2 mx-4 rounded-xl p-4 animate-scale-in">
            <div className="flex flex-col gap-3">
              <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-text-primary transition-colors">Fitur</a>
              <a href="#stats" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-text-primary transition-colors">Tentang</a>
              <a href="#testimonials" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-text-primary transition-colors">Testimoni</a>
              <div className="divider-gold" />
              <Link to="/login" className="btn-glass text-sm py-2.5 text-center">Masuk</Link>
              <Link to="/login" className="btn-gold text-sm py-2.5 text-center">Mulai Sekarang</Link>
            </div>
          </div>
        )}
      </nav>

      {/* ═══ Hero ═══ */}
      <section className="relative min-h-screen flex items-center justify-center pt-20">
        {/* Ambient glow orbs */}
        <div className="absolute top-[-10%] right-[-5%] w-[600px] h-[600px] bg-[radial-gradient(circle,rgba(212,175,55,0.07)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-[-10%] left-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(212,175,55,0.04)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
        <div className="absolute top-[40%] left-[30%] w-[300px] h-[300px] bg-[radial-gradient(circle,rgba(59,130,246,0.03)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 text-center relative z-10">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-accent/[0.08] border border-accent/15 mb-8 animate-fade-in-up">
            <span className="w-1.5 h-1.5 rounded-full bg-success animate-pulse" />
            <span className="text-accent text-xs font-medium tracking-wide">Sekarang Tersedia di 50+ Kota</span>
          </div>

          {/* Headline */}
          <h1 className="text-5xl md:text-7xl lg:text-8xl font-bold tracking-tight leading-[1.05] animate-fade-in-up stagger-1">
            <span className="text-text-primary">Pesan </span>
            <span className="gold-text">Studio Sempurna</span>
          </h1>

          {/* Subtitle */}
          <p className="mt-6 text-text-secondary text-lg md:text-xl max-w-2xl mx-auto leading-relaxed animate-fade-in-up stagger-2">
            Platform premium untuk musisi menemukan, memesan, dan mengelola
            studio rekaman profesional — semua dalam satu tempat.
          </p>

          {/* CTA buttons */}
          <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4 animate-fade-in-up stagger-3">
            <Link
              to="/login"
              className="btn-gold text-base py-3.5 px-8 min-w-[200px]"
            >
              Mulai Pesan
            </Link>
            <a
              href="#features"
              className="btn-glass text-base py-3.5 px-8 min-w-[200px] text-center"
            >
              Pelajari Lebih Lanjut ↓
            </a>
          </div>

          {/* Trust indicators */}
          <div className="mt-16 flex items-center justify-center gap-8 animate-fade-in-up stagger-4">
            <div className="flex -space-x-2">
              {[...Array(5)].map((_, i) => (
                <div key={i} className="w-8 h-8 rounded-full bg-gradient-to-br from-accent/20 to-surface-light border-2 border-primary flex items-center justify-center text-[0.6rem] font-medium text-accent">
                  {String.fromCharCode(65 + i)}
                </div>
              ))}
            </div>
            <div className="text-left">
              <div className="flex items-center gap-1">
                {[...Array(5)].map((_, i) => (
                  <span key={i} className="text-warning text-xs">★</span>
                ))}
              </div>
              <p className="text-text-muted text-xs mt-0.5">Disukai oleh 10.000+ musisi</p>
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 animate-float">
          <div className="w-6 h-10 rounded-full border border-border-light flex items-start justify-center p-1.5">
            <div className="w-1.5 h-2.5 rounded-full bg-accent/50 animate-pulse" />
          </div>
        </div>
      </section>

      {/* ═══ Stats ═══ */}
      <section id="stats" className="py-20 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-accent/[0.02] to-transparent pointer-events-none" />
        <div className="max-w-5xl mx-auto px-6">
          <div className="glass-strong rounded-2xl p-8 md:p-12">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
              {stats.map((stat, i) => (
                <div key={stat.label} className={`text-center animate-fade-in-up stagger-${i + 1}`}>
                  <p className="text-3xl md:text-4xl font-bold gold-text-static">{stat.value}</p>
                  <p className="text-text-muted text-sm mt-1">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Features ═══ */}
      <section id="features" className="py-24 relative">
        <div className="absolute top-0 left-[20%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(212,175,55,0.04)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 relative z-10">
          {/* Section header */}
          <div className="text-center mb-16">
            <p className="text-accent text-xs font-medium tracking-widest uppercase mb-3">Mengapa StudioBook</p>
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight">
              <span className="text-text-primary">Semua yang Anda Butuhkan untuk </span>
              <span className="gold-text-static">Berkarya</span>
            </h2>
            <p className="text-text-secondary mt-4 max-w-xl mx-auto">
              Platform lengkap yang dirancang untuk musisi, produser, dan pemilik studio.
            </p>
          </div>

          {/* Features grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {features.map((feature, i) => (
              <div
                key={feature.title}
                className={`card-luxury p-7 group animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}
              >
                <div className="w-12 h-12 rounded-xl bg-accent/[0.08] border border-accent/10 flex items-center justify-center text-xl mb-5 group-hover:scale-110 transition-transform duration-300">
                  {feature.icon}
                </div>
                <h3 className="text-text-primary font-semibold mb-2">{feature.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed">{feature.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ How It Works ═══ */}
      <section className="py-24 relative">
        <div className="max-w-5xl mx-auto px-6">
          <div className="text-center mb-16">
            <p className="text-accent text-xs font-medium tracking-widest uppercase mb-3">Cara Kerja</p>
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight">
              <span className="text-text-primary">Tiga Langkah Menuju </span>
              <span className="gold-text-static">Sesi Anda</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[
              { step: '01', icon: '🔍', title: 'Temukan', description: 'Jelajahi ratusan studio terverifikasi dan temukan yang sempurna untuk genre dan anggaran Anda.' },
              { step: '02', icon: '📅', title: 'Pesan', description: 'Pilih tanggal, waktu, dan ruangan favorit Anda. Konfirmasi pemesanan hanya dalam beberapa ketukan.' },
              { step: '03', icon: '🎶', title: 'Berkarya', description: 'Datang ke studio, colok peralatan, dan biarkan musik mengalir. Sesederhana itu.' },
            ].map((item, i) => (
              <div key={item.step} className={`text-center animate-fade-in-up stagger-${i + 1}`}>
                <div className="relative inline-block mb-6">
                  <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-accent/15 to-accent/5 border border-accent/10 flex items-center justify-center text-3xl mx-auto">
                    {item.icon}
                  </div>
                  <span className="absolute -top-2 -right-2 w-7 h-7 rounded-full bg-accent text-primary text-xs font-bold flex items-center justify-center">{item.step}</span>
                </div>
                <h3 className="text-text-primary font-semibold text-lg mb-2">{item.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed max-w-xs mx-auto">{item.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ Testimonials ═══ */}
      <section id="testimonials" className="py-24 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-accent/[0.015] to-transparent pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 relative z-10">
          <div className="text-center mb-16">
            <p className="text-accent text-xs font-medium tracking-widest uppercase mb-3">Testimoni</p>
            <h2 className="text-3xl md:text-5xl font-bold tracking-tight">
              <span className="text-text-primary">Disukai oleh </span>
              <span className="gold-text-static">Musisi</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {testimonials.map((t, i) => (
              <div key={t.name} className={`card-luxury p-7 animate-fade-in-up stagger-${i + 1}`}>
                {/* Stars */}
                <div className="flex items-center gap-0.5 mb-4">
                  {[...Array(t.rating)].map((_, j) => (
                    <span key={j} className="text-warning text-sm">★</span>
                  ))}
                </div>

                {/* Quote */}
                <p className="text-text-secondary text-sm leading-relaxed mb-6">"{t.quote}"</p>

                {/* Author */}
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent/15 to-accent/5 border border-accent/10 flex items-center justify-center text-accent text-sm font-semibold">
                    {t.name.charAt(0)}
                  </div>
                  <div>
                    <p className="text-text-primary text-sm font-medium">{t.name}</p>
                    <p className="text-text-muted text-xs">{t.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ CTA ═══ */}
      <section className="py-24 relative">
        <div className="max-w-4xl mx-auto px-6">
          <div className="glass-strong rounded-3xl p-10 md:p-16 text-center relative overflow-hidden">
            {/* Decorative glow */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[400px] h-[200px] bg-[radial-gradient(ellipse,rgba(212,175,55,0.1)_0%,transparent_70%)] pointer-events-none" />

            <div className="relative z-10">
              <h2 className="text-3xl md:text-5xl font-bold tracking-tight mb-4">
                <span className="text-text-primary">Siap untuk </span>
                <span className="gold-text-static">Berkarya</span>
                <span className="text-text-primary">?</span>
              </h2>
              <p className="text-text-secondary text-lg max-w-lg mx-auto mb-8">
                Bergabung dengan ribuan musisi yang mempercayai StudioBook untuk sesi rekaman mereka.
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                <Link to="/login" className="btn-gold text-base py-3.5 px-8 min-w-[200px]">
                  Mulai Gratis
                </Link>
                <Link to="/login" className="btn-glass text-base py-3.5 px-8 min-w-[200px] text-center">
                  Masuk ke Dashboard
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Footer ═══ */}
      <footer className="border-t border-border/40 py-12">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-10">
            {/* Brand */}
            <div className="md:col-span-1">
              <div className="flex items-center gap-2.5 mb-4">
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/25 to-accent/5 flex items-center justify-center border border-accent/10">
                  <span className="text-sm">🎸</span>
                </div>
                <span className="gold-text-static font-bold text-lg">StudioBook</span>
              </div>
              <p className="text-text-muted text-sm leading-relaxed">
                Platform premium untuk musisi menemukan dan memesan studio profesional.
              </p>
            </div>

            {/* Links */}
            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-4">Platform</h4>
              <div className="space-y-2.5">
                <a href="#features" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Fitur</a>
                <a href="#stats" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Tentang</a>
                <a href="#testimonials" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Testimoni</a>
                <Link to="/login" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Masuk</Link>
              </div>
            </div>

            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-4">Untuk Studio</h4>
              <div className="space-y-2.5">
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Daftarkan Studio</a>
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Harga</a>
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Sumber Daya</a>
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Dukungan</a>
              </div>
            </div>

            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-4">Legal</h4>
              <div className="space-y-2.5">
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Kebijakan Privasi</a>
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Syarat & Ketentuan</a>
                <a href="#" className="block text-text-muted text-sm hover:text-text-primary transition-colors">Kebijakan Cookie</a>
              </div>
            </div>
          </div>

          <div className="divider-gold mt-10 mb-6" />

          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <p className="text-text-muted text-xs">
              © 2025 StudioBook. Hak cipta dilindungi. Dibuat dengan ♪
            </p>
            <div className="flex items-center gap-4">
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-sm">𝕏</a>
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-sm">📷</a>
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-sm">💬</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
