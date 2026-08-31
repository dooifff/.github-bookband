import { Link } from 'react-router-dom'
import { useState, useEffect, useRef } from 'react'

/* ═══════════════════════════════════════════════
   STUDIOBOOK — Premium Luxury Landing Page
   ═══════════════════════════════════════════════ */

const features = [
  {
    icon: '🎵',
    title: 'Studio Premium',
    description: 'Akses studio musik kelas atas dengan peralatan profesional dan ruangan yang diawasi akustiknya.',
    gradient: 'from-amber-500/20 to-yellow-600/5',
  },
  {
    icon: '📅',
    title: 'Pemesanan Mudah',
    description: 'Pesan waktu studio favorit Anda dalam hitungan detik dengan sistem penjadwalan kami yang intuitif.',
    gradient: 'from-blue-500/20 to-cyan-600/5',
  },
  {
    icon: '⚡',
    title: 'Konfirmasi Instan',
    description: 'Dapatkan konfirmasi pemesanan segera dan pembaruan status secara real-time.',
    gradient: 'from-purple-500/20 to-pink-600/5',
  },
  {
    icon: '💳',
    title: 'Pembayaran Aman',
    description: 'Berbagai opsi pembayaran dengan enkripsi tingkat bank untuk transaksi yang aman dan mudah.',
    gradient: 'from-emerald-500/20 to-teal-600/5',
  },
  {
    icon: '⭐',
    title: 'Ulasan Terverifikasi',
    description: 'Baca ulasan autentik dari musisi lain untuk menemukan studio yang sempurna untuk kebutuhan Anda.',
    gradient: 'from-orange-500/20 to-red-600/5',
  },
  {
    icon: '📱',
    title: 'Ramah Seluler',
    description: 'Kelola pemesanan Anda di mana saja dengan platform responsif kami yang bekerja di semua perangkat.',
    gradient: 'from-pink-500/20 to-rose-600/5',
  },
]

const stats = [
  { value: '500+', label: 'Studio', icon: '🎙️' },
  { value: '10K+', label: 'Pemesanan', icon: '📅' },
  { value: '4.9', label: 'Penilaian', icon: '⭐' },
  { value: '50+', label: 'Kota', icon: '🏙️' },
]

const testimonials = [
  {
    name: 'Rizky Pratama',
    role: 'Artis Independen',
    quote: 'StudioBook membuat pencarian studio sempurna menjadi sangat mudah. Proses pemesanannya mulus dan studio-studionya luar biasa.',
    rating: 5,
    avatar: '🎸',
  },
  {
    name: 'Anisa Dewi',
    role: 'Produser Musik',
    quote: 'Sebagai produser, saya membutuhkan studio yang andal. StudioBook selalu memberikan opsi berkualitas dengan harga yang transparan.',
    rating: 5,
    avatar: '🎹',
  },
  {
    name: 'Budi Santoso',
    role: 'Pemilik Studio',
    quote: 'Sejak bergabung dengan StudioBook, pemesanan studio saya meningkat 40%. Platform ini mengubah permainan bagi pemilik studio.',
    rating: 5,
    avatar: '🎚️',
  },
]

const pricingPlans = [
  {
    name: 'Basic',
    price: 'Gratis',
    description: 'Untuk musisi pemula',
    features: ['1 Akun', 'Akses Studio Dasar', 'Pemesanan Standar', 'Support Email'],
    cta: 'Mulai Gratis',
    popular: false,
  },
  {
    name: 'Pro',
    price: 'Rp99K',
    period: '/bulan',
    description: 'Untuk musisi serius',
    features: ['1 Akun Pro', 'Semua Studio Premium', 'Pemesanan Prioritas', 'Support 24/7', 'Analitik', 'Riwayat Booking'],
    cta: 'Upgrade Pro',
    popular: true,
  },
  {
    name: 'Studio',
    price: 'Rp299K',
    period: '/bulan',
    description: 'Untuk pemilik studio',
    features: ['Manajemen Studio', 'Dashboard Analitik', 'Promosi Premium', 'Support Dedicated', 'API Access', 'White Label'],
    cta: 'Mulai Jual',
    popular: false,
  },
]

/* ── Animated Counter ── */
function AnimatedCounter({ target, suffix = '' }: { target: number; suffix?: string }) {
  const [count, setCount] = useState(0)
  const ref = useRef<HTMLDivElement>(null)
  const hasAnimated = useRef(false)

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting && !hasAnimated.current) {
          hasAnimated.current = true
          const duration = 2000
          const start = performance.now()
          const animate = (now: number) => {
            const progress = Math.min((now - start) / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            setCount(Math.floor(eased * target))
            if (progress < 1) requestAnimationFrame(animate)
          }
          requestAnimationFrame(animate)
        }
      },
      { threshold: 0.3 }
    )
    if (ref.current) observer.observe(ref.current)
    return () => observer.disconnect()
  }, [target])

  return <div ref={ref}>{count}{suffix}</div>
}

export default function LandingPage() {
  const [scrollY, setScrollY] = useState(0)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [activeTestimonial, setActiveTestimonial] = useState(0)

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  // Auto-rotate testimonials
  useEffect(() => {
    const timer = setInterval(() => {
      setActiveTestimonial((prev) => (prev + 1) % testimonials.length)
    }, 5000)
    return () => clearInterval(timer)
  }, [])

  const isScrolled = scrollY > 50

  return (
    <div className="min-h-screen bg-primary text-text-primary overflow-x-hidden">
      {/* ═══ Floating Particles ═══ */}
      <div className="fixed inset-0 pointer-events-none z-0 overflow-hidden">
        {[...Array(20)].map((_, i) => (
          <div
            key={i}
            className="absolute rounded-full bg-accent/10 animate-float"
            style={{
              width: `${Math.random() * 4 + 2}px`,
              height: `${Math.random() * 4 + 2}px`,
              left: `${Math.random() * 100}%`,
              top: `${Math.random() * 100}%`,
              animationDelay: `${Math.random() * 5}s`,
              animationDuration: `${Math.random() * 3 + 4}s`,
            }}
          />
        ))}
      </div>

      {/* ═══ Navigation ═══ */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        isScrolled ? 'glass-strong py-3 shadow-lg shadow-black/20' : 'py-5 bg-transparent'
      }`}>
        <div className="max-w-7xl mx-auto px-6 flex items-center justify-between">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-3 group">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent to-accent-dark flex items-center justify-center shadow-lg shadow-accent/20 group-hover:shadow-accent/40 transition-all duration-300 group-hover:scale-110">
              <span className="text-base">🎸</span>
            </div>
            <span className="gold-text-static font-bold text-xl tracking-tight">StudioBook</span>
          </Link>

          {/* Desktop nav */}
          <div className="hidden md:flex items-center gap-10">
            <a href="#features" className="text-text-secondary text-sm hover:text-accent transition-colors duration-300 relative group">
              Fitur
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-accent group-hover:w-full transition-all duration-300" />
            </a>
            <a href="#pricing" className="text-text-secondary text-sm hover:text-accent transition-colors duration-300 relative group">
              Harga
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-accent group-hover:w-full transition-all duration-300" />
            </a>
            <a href="#testimonials" className="text-text-secondary text-sm hover:text-accent transition-colors duration-300 relative group">
              Testimoni
              <span className="absolute -bottom-1 left-0 w-0 h-0.5 bg-accent group-hover:w-full transition-all duration-300" />
            </a>
          </div>

          {/* CTA */}
          <div className="hidden md:flex items-center gap-4">
            <Link to="/login" className="btn-glass text-sm py-2.5 px-6">Masuk</Link>
            <Link to="/login" className="btn-gold text-sm py-2.5 px-6 shadow-lg shadow-accent/20 hover:shadow-accent/40">Mulai Sekarang</Link>
          </div>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden text-text-secondary hover:text-text-primary transition-colors p-2"
          >
            <svg className="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
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
          <div className="md:hidden glass-strong mt-2 mx-4 rounded-2xl p-5 animate-scale-in shadow-xl shadow-black/30">
            <div className="flex flex-col gap-4">
              <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-accent transition-colors">Fitur</a>
              <a href="#pricing" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-accent transition-colors">Harga</a>
              <a href="#testimonials" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-accent transition-colors">Testimoni</a>
              <div className="divider-gold" />
              <Link to="/login" className="btn-glass text-sm py-3 text-center">Masuk</Link>
              <Link to="/login" className="btn-gold text-sm py-3 text-center shadow-lg shadow-accent/20">Mulai Sekarang</Link>
            </div>
          </div>
        )}
      </nav>

      {/* ═══ Hero Section ═══ */}
      <section className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
        {/* Ambient glow orbs */}
        <div className="absolute top-[-20%] right-[-10%] w-[800px] h-[800px] bg-[radial-gradient(circle,rgba(212,175,55,0.1)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none animate-pulse" />
        <div className="absolute bottom-[-15%] left-[-10%] w-[700px] h-[700px] bg-[radial-gradient(circle,rgba(212,175,55,0.06)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
        <div className="absolute top-[30%] left-[20%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(59,130,246,0.04)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
        <div className="absolute top-[60%] right-[20%] w-[300px] h-[300px] bg-[radial-gradient(circle,rgba(168,85,247,0.04)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

        {/* Grid pattern overlay */}
        <div className="absolute inset-0 opacity-[0.02]" style={{
          backgroundImage: 'linear-gradient(rgba(212,175,55,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(212,175,55,0.3) 1px, transparent 1px)',
          backgroundSize: '60px 60px',
        }} />

        <div className="max-w-7xl mx-auto px-6 text-center relative z-10">
          {/* Badge */}
          <div className="inline-flex items-center gap-3 px-5 py-2.5 rounded-full bg-accent/[0.08] border border-accent/20 mb-10 animate-fade-in-up luxury-shadow">
            <span className="relative flex h-2.5 w-2.5">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75" />
              <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-success" />
            </span>
            <span className="text-accent text-xs font-semibold tracking-widest uppercase">Sekarang Tersedia di 50+ Kota</span>
          </div>

          {/* Headline */}
          <h1 className="text-5xl md:text-7xl lg:text-[5.5rem] font-bold tracking-tight leading-[1.02] animate-fade-in-up stagger-1">
            <span className="text-text-primary">Pesan </span>
            <span className="gold-text">Studio</span>
            <br />
            <span className="gold-text">Sempurna</span>
          </h1>

          {/* Decorative line */}
          <div className="w-24 h-1 mx-auto mt-8 mb-8 rounded-full bg-gradient-to-r from-transparent via-accent to-transparent animate-fade-in-up stagger-2" />

          {/* Subtitle */}
          <p className="text-text-secondary text-lg md:text-xl max-w-2xl mx-auto leading-relaxed animate-fade-in-up stagger-2">
            Platform premium untuk musisi menemukan, memesan, dan mengelola
            studio rekaman profesional — <span className="text-accent font-medium">semua dalam satu tempat.</span>
          </p>

          {/* CTA buttons */}
          <div className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-5 animate-fade-in-up stagger-3">
            <Link
              to="/login"
              className="btn-gold text-base py-4 px-10 min-w-[220px] shadow-xl shadow-accent/25 hover:shadow-accent/40 text-base font-bold"
            >
              🚀 Mulai Pesan
            </Link>
            <a
              href="#features"
              className="btn-glass text-base py-4 px-10 min-w-[220px] text-center"
            >
              Pelajari Lebih Lanjut ↓
            </a>
          </div>

          {/* Trust indicators */}
          <div className="mt-16 flex flex-col sm:flex-row items-center justify-center gap-8 animate-fade-in-up stagger-4">
            <div className="flex -space-x-3">
              {[...Array(6)].map((_, i) => (
                <div key={i} className="w-10 h-10 rounded-full bg-gradient-to-br from-accent/25 to-surface-light border-2 border-primary flex items-center justify-center text-xs font-bold text-accent luxury-shadow">
                  {String.fromCharCode(65 + i)}
                </div>
              ))}
            </div>
            <div className="text-left">
              <div className="flex items-center gap-1">
                {[...Array(5)].map((_, i) => (
                  <span key={i} className="text-warning text-sm">★</span>
                ))}
              </div>
              <p className="text-text-muted text-xs mt-1">Disukai oleh <span className="text-accent font-semibold">10.000+</span> musisi</p>
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-float">
          <div className="w-7 h-12 rounded-full border-2 border-accent/30 flex items-start justify-center p-2 luxury-shadow">
            <div className="w-1.5 h-3 rounded-full bg-accent/60 animate-bounce" />
          </div>
        </div>
      </section>

      {/* ═══ Stats Section ═══ */}
      <section id="stats" className="py-24 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-accent/[0.03] to-transparent pointer-events-none" />
        <div className="max-w-6xl mx-auto px-6">
          <div className="glass-strong rounded-3xl p-10 md:p-14 luxury-shadow-lg">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-10">
              {stats.map((stat, i) => (
                <div key={stat.label} className={`text-center group animate-fade-in-up stagger-${i + 1}`}>
                  <div className="text-3xl mb-3 group-hover:scale-125 transition-transform duration-300">{stat.icon}</div>
                  <p className="text-4xl md:text-5xl font-bold gold-text-static">
                    <AnimatedCounter target={parseInt(stat.value.replace(/[^0-9]/g, ''))} suffix={stat.value.replace(/[0-9]/g, '')} />
                  </p>
                  <p className="text-text-muted text-sm mt-2 font-medium">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Features Section ═══ */}
      <section id="features" className="py-28 relative">
        <div className="absolute top-0 left-[15%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(212,175,55,0.05)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 right-[10%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(59,130,246,0.03)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 relative z-10">
          {/* Section header */}
          <div className="text-center mb-20">
            <p className="text-accent text-xs font-semibold tracking-widest uppercase mb-4">✦ Mengapa StudioBook</p>
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight">
              <span className="text-text-primary">Semua yang Anda Butuhkan untuk </span>
              <span className="gold-text-static">Berkarya</span>
            </h2>
            <p className="text-text-secondary mt-5 max-w-xl mx-auto text-lg">
              Platform lengkap yang dirancang untuk musisi, produser, dan pemilik studio.
            </p>
            <div className="w-16 h-0.5 mx-auto mt-6 rounded-full bg-gradient-to-r from-transparent via-accent to-transparent" />
          </div>

          {/* Features grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature, i) => (
              <div
                key={feature.title}
                className={`card-luxury p-8 group animate-fade-in-up stagger-${Math.min(i + 1, 8)} relative overflow-hidden`}
              >
                {/* Gradient overlay on hover */}
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.gradient} opacity-0 group-hover:opacity-100 transition-opacity duration-500`} />
                
                <div className="relative z-10">
                  <div className="w-14 h-14 rounded-2xl bg-accent/[0.1] border border-accent/15 flex items-center justify-center text-2xl mb-6 group-hover:scale-110 group-hover:shadow-lg group-hover:shadow-accent/10 transition-all duration-300">
                    {feature.icon}
                  </div>
                  <h3 className="text-text-primary font-semibold text-lg mb-3">{feature.title}</h3>
                  <p className="text-text-secondary text-sm leading-relaxed">{feature.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ How It Works ═══ */}
      <section className="py-28 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-accent/[0.02] to-transparent pointer-events-none" />
        <div className="max-w-6xl mx-auto px-6 relative z-10">
          <div className="text-center mb-20">
            <p className="text-accent text-xs font-semibold tracking-widest uppercase mb-4">✦ Cara Kerja</p>
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight">
              <span className="text-text-primary">Tiga Langkah Menuju </span>
              <span className="gold-text-static">Sesi Anda</span>
            </h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-10 relative">
            {/* Connecting line */}
            <div className="hidden md:block absolute top-10 left-[20%] right-[20%] h-0.5 bg-gradient-to-r from-accent/20 via-accent/40 to-accent/20" />
            
            {[
              { step: '01', icon: '🔍', title: 'Temukan', description: 'Jelajahi ratusan studio terverifikasi dan temukan yang sempurna untuk genre dan anggaran Anda.' },
              { step: '02', icon: '📅', title: 'Pesan', description: 'Pilih tanggal, waktu, dan ruangan favorit Anda. Konfirmasi pemesanan hanya dalam beberapa ketukan.' },
              { step: '03', icon: '🎶', title: 'Berkarya', description: 'Datang ke studio, colok peralatan, dan biarkan musik mengalir. Sesederhana itu.' },
            ].map((item, i) => (
              <div key={item.step} className={`text-center relative animate-fade-in-up stagger-${i + 1}`}>
                <div className="relative inline-block mb-8">
                  <div className="w-24 h-24 rounded-3xl bg-gradient-to-br from-accent/20 to-accent/5 border border-accent/15 flex items-center justify-center text-4xl mx-auto luxury-shadow group-hover:luxury-shadow-glow transition-all duration-300">
                    {item.icon}
                  </div>
                  <span className="absolute -top-3 -right-3 w-9 h-9 rounded-full bg-gradient-to-br from-accent to-accent-dark text-primary text-sm font-bold flex items-center justify-center luxury-shadow">
                    {item.step}
                  </span>
                </div>
                <h3 className="text-text-primary font-bold text-xl mb-3">{item.title}</h3>
                <p className="text-text-secondary text-sm leading-relaxed max-w-xs mx-auto">{item.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ Pricing Section ═══ */}
      <section id="pricing" className="py-28 relative">
        <div className="max-w-6xl mx-auto px-6 relative z-10">
          <div className="text-center mb-20">
            <p className="text-accent text-xs font-semibold tracking-widest uppercase mb-4">✦ Harga</p>
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight">
              <span className="text-text-primary">Pilih </span>
              <span className="gold-text-static">Paket Anda</span>
            </h2>
            <p className="text-text-secondary mt-5 max-w-xl mx-auto text-lg">
              Mulai gratis, upgrade saat Anda siap.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {pricingPlans.map((plan, i) => (
              <div
                key={plan.name}
                className={`relative rounded-3xl p-8 transition-all duration-300 ${
                  plan.popular
                    ? 'glass-strong border-2 border-accent/30 luxury-shadow-glow scale-105'
                    : 'card-luxury'
                } animate-fade-in-up stagger-${i + 1}`}
              >
                {plan.popular && (
                  <div className="absolute -top-4 left-1/2 -translate-x-1/2 px-4 py-1.5 rounded-full bg-gradient-to-r from-accent to-accent-dark text-primary text-xs font-bold shadow-lg shadow-accent/30">
                    ✦ POPULER
                  </div>
                )}
                
                <div className="text-center mb-8">
                  <h3 className="text-text-primary font-bold text-xl mb-2">{plan.name}</h3>
                  <p className="text-text-muted text-sm mb-4">{plan.description}</p>
                  <div className="flex items-baseline justify-center gap-1">
                    <span className={`text-4xl font-bold ${plan.popular ? 'gold-text-static' : 'text-text-primary'}`}>
                      {plan.price}
                    </span>
                    {plan.period && <span className="text-text-muted text-sm">{plan.period}</span>}
                  </div>
                </div>

                <ul className="space-y-3 mb-8">
                  {plan.features.map((feature) => (
                    <li key={feature} className="flex items-center gap-3 text-sm">
                      <span className="text-accent">✓</span>
                      <span className="text-text-secondary">{feature}</span>
                    </li>
                  ))}
                </ul>

                <Link
                  to="/login"
                  className={`block text-center py-3.5 rounded-xl font-semibold transition-all duration-300 ${
                    plan.popular
                      ? 'btn-gold shadow-lg shadow-accent/25 hover:shadow-accent/40'
                      : 'btn-glass'
                  }`}
                >
                  {plan.cta}
                </Link>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ Testimonials ═══ */}
      <section id="testimonials" className="py-28 relative">
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-accent/[0.02] to-transparent pointer-events-none" />

        <div className="max-w-7xl mx-auto px-6 relative z-10">
          <div className="text-center mb-20">
            <p className="text-accent text-xs font-semibold tracking-widest uppercase mb-4">✦ Testimoni</p>
            <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight">
              <span className="text-text-primary">Disukai oleh </span>
              <span className="gold-text-static">Musisi</span>
            </h2>
          </div>

          {/* Desktop grid */}
          <div className="hidden md:grid grid-cols-3 gap-8">
            {testimonials.map((t, i) => (
              <div key={t.name} className={`card-luxury p-8 animate-fade-in-up stagger-${i + 1} relative group`}>
                {/* Quote icon */}
                <div className="absolute top-6 right-6 text-6xl text-accent/10 font-serif leading-none">"</div>
                
                {/* Stars */}
                <div className="flex items-center gap-1 mb-5">
                  {[...Array(t.rating)].map((_, j) => (
                    <span key={j} className="text-warning text-base">★</span>
                  ))}
                </div>

                {/* Quote */}
                <p className="text-text-secondary text-sm leading-relaxed mb-8 relative z-10">"{t.quote}"</p>

                {/* Author */}
                <div className="flex items-center gap-4">
                  <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-accent/20 to-accent/5 border border-accent/15 flex items-center justify-center text-xl">
                    {t.avatar}
                  </div>
                  <div>
                    <p className="text-text-primary text-sm font-semibold">{t.name}</p>
                    <p className="text-text-muted text-xs">{t.role}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Mobile carousel */}
          <div className="md:hidden">
            <div className="card-luxury p-8 relative">
              <div className="absolute top-6 right-6 text-6xl text-accent/10 font-serif leading-none">"</div>
              <div className="flex items-center gap-1 mb-5">
                {[...Array(testimonials[activeTestimonial].rating)].map((_, j) => (
                  <span key={j} className="text-warning text-base">★</span>
                ))}
              </div>
              <p className="text-text-secondary text-sm leading-relaxed mb-8">"{testimonials[activeTestimonial].quote}"</p>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-accent/20 to-accent/5 border border-accent/15 flex items-center justify-center text-xl">
                  {testimonials[activeTestimonial].avatar}
                </div>
                <div>
                  <p className="text-text-primary text-sm font-semibold">{testimonials[activeTestimonial].name}</p>
                  <p className="text-text-muted text-xs">{testimonials[activeTestimonial].role}</p>
                </div>
              </div>
            </div>
            {/* Dots */}
            <div className="flex justify-center gap-2 mt-6">
              {testimonials.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setActiveTestimonial(i)}
                  className={`w-2 h-2 rounded-full transition-all duration-300 ${
                    i === activeTestimonial ? 'bg-accent w-6' : 'bg-accent/30'
                  }`}
                />
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* ═══ CTA Section ═══ */}
      <section className="py-28 relative">
        <div className="max-w-5xl mx-auto px-6">
          <div className="glass-strong rounded-[2rem] p-12 md:p-20 text-center relative overflow-hidden luxury-shadow-lg">
            {/* Decorative glows */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[500px] h-[250px] bg-[radial-gradient(ellipse,rgba(212,175,55,0.12)_0%,transparent_70%)] pointer-events-none" />
            <div className="absolute bottom-0 left-1/4 w-[300px] h-[150px] bg-[radial-gradient(ellipse,rgba(59,130,246,0.06)_0%,transparent_70%)] pointer-events-none" />
            <div className="absolute bottom-0 right-1/4 w-[300px] h-[150px] bg-[radial-gradient(ellipse,rgba(168,85,247,0.06)_0%,transparent_70%)] pointer-events-none" />

            <div className="relative z-10">
              <div className="text-5xl mb-6">🎸</div>
              <h2 className="text-3xl md:text-5xl lg:text-6xl font-bold tracking-tight mb-6">
                <span className="text-text-primary">Siap untuk </span>
                <span className="gold-text-static">Berkarya</span>
                <span className="text-text-primary">?</span>
              </h2>
              <p className="text-text-secondary text-lg max-w-lg mx-auto mb-10 leading-relaxed">
                Bergabung dengan ribuan musisi yang mempercayai StudioBook untuk sesi rekaman mereka.
              </p>
              <div className="flex flex-col sm:flex-row items-center justify-center gap-5">
                <Link to="/login" className="btn-gold text-base py-4 px-10 min-w-[220px] shadow-xl shadow-accent/25 hover:shadow-accent/40 font-bold">
                  🚀 Mulai Gratis
                </Link>
                <Link to="/login" className="btn-glass text-base py-4 px-10 min-w-[220px] text-center">
                  Masuk ke Dashboard
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Footer ═══ */}
      <footer className="border-t border-border/40 py-16 relative">
        <div className="absolute inset-0 bg-gradient-to-t from-accent/[0.02] to-transparent pointer-events-none" />
        <div className="max-w-7xl mx-auto px-6 relative z-10">
          <div className="grid grid-cols-1 md:grid-cols-5 gap-12">
            {/* Brand */}
            <div className="md:col-span-2">
              <div className="flex items-center gap-3 mb-5">
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent to-accent-dark flex items-center justify-center shadow-lg shadow-accent/20">
                  <span className="text-base">🎸</span>
                </div>
                <span className="gold-text-static font-bold text-xl">StudioBook</span>
              </div>
              <p className="text-text-muted text-sm leading-relaxed max-w-sm">
                Platform premium untuk musisi menemukan dan memesan studio profesional. Dibuat dengan ♪ untuk musisi Indonesia.
              </p>
              <div className="flex items-center gap-4 mt-6">
                <a href="#" className="w-9 h-9 rounded-xl bg-surface-light border border-border flex items-center justify-center text-text-muted hover:text-accent hover:border-accent/30 transition-all duration-300">𝕏</a>
                <a href="#" className="w-9 h-9 rounded-xl bg-surface-light border border-border flex items-center justify-center text-text-muted hover:text-accent hover:border-accent/30 transition-all duration-300">📷</a>
                <a href="#" className="w-9 h-9 rounded-xl bg-surface-light border border-border flex items-center justify-center text-text-muted hover:text-accent hover:border-accent/30 transition-all duration-300">💬</a>
              </div>
            </div>

            {/* Links */}
            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-5">Platform</h4>
              <div className="space-y-3">
                <a href="#features" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Fitur</a>
                <a href="#pricing" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Harga</a>
                <a href="#testimonials" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Testimoni</a>
                <Link to="/login" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Masuk</Link>
              </div>
            </div>

            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-5">Untuk Studio</h4>
              <div className="space-y-3">
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Daftarkan Studio</a>
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Harga</a>
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Sumber Daya</a>
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Dukungan</a>
              </div>
            </div>

            <div>
              <h4 className="text-text-primary text-sm font-semibold mb-5">Legal</h4>
              <div className="space-y-3">
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Kebijakan Privasi</a>
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Syarat & Ketentuan</a>
                <a href="#" className="block text-text-muted text-sm hover:text-accent transition-colors duration-300">Kebijakan Cookie</a>
              </div>
            </div>
          </div>

          <div className="divider-gold mt-12 mb-8" />

          <div className="flex flex-col md:flex-row items-center justify-between gap-4">
            <p className="text-text-muted text-xs">
              © 2025 StudioBook. Hak cipta dilindungi. Dibuat dengan ♪ untuk musisi Indonesia.
            </p>
            <div className="flex items-center gap-6">
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-xs">Kebijakan Privasi</a>
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-xs">Syarat</a>
              <a href="#" className="text-text-muted hover:text-accent transition-colors text-xs">Sitemap</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
