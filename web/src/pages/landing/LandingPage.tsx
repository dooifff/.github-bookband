import { Link } from 'react-router-dom'
import { useState, useEffect, useRef } from 'react'
import api from '../../services/api'

/* ═══════════════════════════════════════════════
   STUDIOBOOK — Grungy Rock Landing Page (Black Nova Style)
   ═══════════════════════════════════════════════ */

const stats = [
  { key: 'total_studios', label: 'STUDIOS', icon: '🎙️' },
  { key: 'total_bookings', label: 'BOOKINGS', icon: '📅' },
  { key: 'average_rating', label: 'RATING', icon: '⭐' },
  { key: 'total_cities', label: 'CITIES', icon: '🏙️' },
]



const upcomingBookings = [
  {
    date: '12',
    month: 'SEP',
    year: '2026',
    studio: 'Studio Harmoni',
    type: 'Recording Session',
    location: 'Jakarta Selatan',
  },
  {
    date: '20',
    month: 'SEP',
    year: '2026',
    studio: 'Studio Rekam Pro',
    type: 'Mixing & Mastering',
    location: 'Bandung',
  },
  {
    date: '03',
    month: 'OCT',
    year: '2026',
    studio: 'Studio Kreatif',
    type: 'Full Day Session',
    location: 'Surabaya',
  },
]

const galleryImages = [
  { icon: '🎸', label: 'Recording' },
  { icon: '🎹', label: 'Production' },
  { icon: '🎚️', label: 'Mixing' },
  { icon: '🎧', label: 'Mastering' },
  { icon: '🎤', label: 'Vocals' },
]

/* ── Animated Counter ── */
function AnimatedCounter({ target, suffix = '', format }: { target: number; suffix?: string; format?: (n: number) => string }) {
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

  return <div ref={ref}>{format ? format(count) : count}{suffix}</div>
}

export default function LandingPage() {
  const [scrollY, setScrollY] = useState(0)
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [platformStats, setPlatformStats] = useState<Record<string, number>>({})

  useEffect(() => {
    const handleScroll = () => setScrollY(window.scrollY)
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  // Fetch real platform stats from the API
  useEffect(() => {
    const fetchStats = async () => {
      try {
        const { data } = await api.get('/stats')
        setPlatformStats(data.data || {})
      } catch (err) {
        console.error('Failed to fetch platform stats:', err)
      }
    }
    fetchStats()
  }, [])

  const isScrolled = scrollY > 50

  return (
    <div className="min-h-screen text-text-primary overflow-x-hidden relative bg-[#050505]">
      {/* ═══ Full-page ambient background ═══ */}
      <div className="fixed inset-0 pointer-events-none z-0">
        {/* Subtle red glow blobs */}
        <div className="absolute top-[10%] left-[5%] w-[600px] h-[600px] bg-[radial-gradient(circle,rgba(229,62,62,0.04)_0%,transparent_70%)] rounded-full blur-3xl" />
        <div className="absolute top-[40%] right-[10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(229,62,62,0.03)_0%,transparent_70%)] rounded-full blur-3xl" />
        <div className="absolute bottom-[20%] left-[20%] w-[450px] h-[450px] bg-[radial-gradient(circle,rgba(229,62,62,0.025)_0%,transparent_70%)] rounded-full blur-3xl" />
      </div>

      {/* ═══ Navigation ═══ */}
      <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        isScrolled ? 'glass-strong py-3 shadow-lg shadow-black/30' : 'py-5 bg-transparent'
      }`}>
        <div className="max-w-7xl mx-auto px-6 flex items-center justify-between">
          {/* Logo */}
          <Link to="/" className="flex items-center gap-3 group">
            <div className="relative">
              <span className="font-black text-2xl tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                STUDIO<span className="text-[#e53e3e]">BOOK</span>
              </span>
            </div>
          </Link>

          {/* Desktop nav */}
          <div className="hidden lg:flex items-center gap-8">
            <a href="#featured" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              STUDIOS
            </a>
            <a href="#upcoming" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              UPCOMING
            </a>
            <a href="#about" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              ABOUT
            </a>
            <a href="#gallery" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              GALLERY
            </a>
            <a href="#contact" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              CONTACT
            </a>
            <Link to="/download" className="text-text-secondary text-sm font-semibold tracking-wider hover:text-[#e53e3e] transition-colors duration-300">
              DOWNLOAD
            </Link>
          </div>

          {/* Social icons + CTA */}
          <div className="hidden lg:flex items-center gap-4">
            <a href="#" className="w-9 h-9 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-text-muted hover:text-[#e53e3e] hover:border-[#e53e3e]/30 transition-all duration-300">
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
            </a>
            <a href="#" className="w-9 h-9 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-text-muted hover:text-[#e53e3e] hover:border-[#e53e3e]/30 transition-all duration-300">
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24"><path d="M19.615 3.184c-3.604-.246-11.631-.245-15.23 0-3.897.266-4.356 2.62-4.385 8.816.029 6.185.484 8.549 4.385 8.816 3.6.245 11.626.246 15.23 0 3.897-.266 4.356-2.62 4.385-8.816-.029-6.185-.484-8.549-4.385-8.816zm-10.615 12.816v-8l8 3.993-8 4.007z"/></svg>
            </a>
            <Link to="/register" className="btn-glass text-sm py-2.5 px-6">
              DAFTAR
            </Link>
            <Link to="/login" className="btn-red text-sm py-2.5 px-6">
              MASUK
            </Link>
          </div>

          {/* Mobile hamburger */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden text-text-secondary hover:text-text-primary transition-colors p-2"
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
          <div className="lg:hidden glass-strong mt-2 mx-4 rounded-xl p-5 animate-scale-in shadow-xl shadow-black/40">
            <div className="flex flex-col gap-4">
              <a href="#featured" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">STUDIOS</a>
              <a href="#upcoming" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">UPCOMING</a>
              <a href="#about" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">ABOUT</a>
              <a href="#gallery" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">GALLERY</a>
              <a href="#contact" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">CONTACT</a>
              <Link to="/download" onClick={() => setMobileMenuOpen(false)} className="text-text-secondary text-sm py-2 hover:text-[#e53e3e] transition-colors font-semibold tracking-wider">DOWNLOAD APP</Link>
              <div className="divider-red" />
              <Link to="/register" className="btn-glass text-sm py-3 text-center">DAFTAR</Link>
              <Link to="/login" className="btn-red text-sm py-3 text-center">MASUK</Link>
            </div>
          </div>
        )}
      </nav>

      {/* ═══ Hero Section ═══ */}
      <section className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
        {/* Red brush stroke effect - left side */}
        <div className="absolute top-0 left-0 w-[200px] h-full opacity-30 pointer-events-none">
          <div className="absolute top-[10%] left-0 w-[150px] h-[300px] bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20300%22%3E%3Cpath%20d%3D%22M0%200%20C20%2050%2080%20100%2030%20150%20C-10%20200%2060%20250%2020%20300%22%20stroke%3D%22%23e53e3e%22%20stroke-width%3D%228%22%20fill%3D%22none%22%20stroke-linecap%3D%22round%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
        </div>

        {/* Red brush stroke effect - right side */}
        <div className="absolute top-0 right-0 w-[200px] h-full opacity-30 pointer-events-none">
          <div className="absolute top-[15%] right-0 w-[150px] h-[300px] bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20300%22%3E%3Cpath%20d%3D%22M100%200%20C80%2050%2020%20100%2070%20150%20C110%20200%2040%20250%2080%20300%22%20stroke%3D%22%23e53e3e%22%20stroke-width%3D%228%22%20fill%3D%22none%22%20stroke-linecap%3D%22round%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
        </div>

        {/* Stage spotlight effects */}
        <div className="absolute top-[-25%] left-[-15%] w-[900px] h-[900px] bg-[radial-gradient(ellipse,rgba(229,62,62,0.06)_0%,transparent_60%)] rounded-full blur-3xl pointer-events-none animate-spotlight" />
        <div className="absolute bottom-[-20%] right-[-15%] w-[800px] h-[800px] bg-[radial-gradient(ellipse,rgba(229,62,62,0.04)_0%,transparent_60%)] rounded-full blur-3xl pointer-events-none animate-spotlight" style={{ animationDelay: '2s' }} />

        {/* Grid pattern overlay */}
        <div className="absolute inset-0 opacity-[0.015]" style={{
          backgroundImage: 'linear-gradient(rgba(229,62,62,0.3) 1px, transparent 1px), linear-gradient(90deg, rgba(229,62,62,0.3) 1px, transparent 1px)',
          backgroundSize: '60px 60px',
        }} />

        <div className="max-w-7xl mx-auto px-6 text-center relative z-10">
          {/* WE ARE label */}
          <p className="text-[#e53e3e] text-sm font-bold tracking-[0.3em] uppercase mb-6 animate-fade-in-up">
            WE ARE
          </p>

          {/* Main headline - large grungy text */}
          <h1 className="animate-fade-in-up stagger-1" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
            <span className="text-white text-6xl md:text-8xl lg:text-9xl font-black tracking-tight block">
              STUDIO
            </span>
            <span className="text-[#e53e3e] text-6xl md:text-8xl lg:text-9xl font-black tracking-tight block">
              BOOK
            </span>
          </h1>

          {/* Subtitle */}
          <p className="text-gray-400 text-lg md:text-xl max-w-2xl mx-auto leading-relaxed mt-8 animate-fade-in-up stagger-2 tracking-wide">
            MUSIC THAT SPEAKS LOUDER.
          </p>

          {/* CTA buttons */}
          <div className="mt-12 flex flex-col sm:flex-row items-center justify-center gap-5 animate-fade-in-up stagger-3">
            <Link
              to="/login"
              className="btn-red text-base py-4 px-10 min-w-[220px] font-bold tracking-wider"
            >
              🎧 MASUK SEKARANG
            </Link>
            <a
              href="#featured"
              className="btn-glass text-base py-4 px-10 min-w-[220px] text-center tracking-wider"
            >
              ▶ JELAJAHI STUDIO
            </a>
          </div>

          {/* Slide indicator */}
          <div className="mt-16 flex items-center justify-center gap-4 animate-fade-in-up stagger-4">
            <span className="text-white text-sm font-bold">01</span>
            <span className="text-text-muted">/</span>
            <span className="text-text-muted text-sm">04</span>
            <div className="flex gap-2 ml-4">
              <button className="w-8 h-8 rounded-full border border-white/20 flex items-center justify-center text-white hover:border-[#e53e3e] hover:text-[#e53e3e] transition-all">
                ←
              </button>
              <button className="w-8 h-8 rounded-full border border-white/20 flex items-center justify-center text-white hover:border-[#e53e3e] hover:text-[#e53e3e] transition-all">
                →
              </button>
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="absolute bottom-10 left-1/2 -translate-x-1/2 animate-float">
          <div className="w-7 h-12 rounded-full border-2 border-[#e53e3e]/30 flex items-start justify-center p-2">
            <div className="w-1.5 h-3 rounded-full bg-[#e53e3e]/60 animate-bounce" />
          </div>
        </div>
      </section>

      {/* ═══ Featured Studios Section ═══ */}
      <section id="featured" className="py-24 relative bg-[#050505]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Left - Album art style */}
            <div className="relative animate-fade-in-up">
              <div className="aspect-square bg-gradient-to-br from-[#1a1a1a] to-[#0d0d0d] rounded-lg overflow-hidden border border-white/5 relative">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="text-center">
                    <span className="text-8xl">🎙️</span>
                    <p className="text-white text-2xl font-black mt-4 tracking-wider" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                      STUDIOBOOK
                    </p>
                    <p className="text-[#e53e3e] text-sm font-semibold tracking-widest mt-2">
                      THE NEW PLATFORM
                    </p>
                  </div>
                </div>
                {/* Red corner accent */}
                <div className="absolute top-0 right-0 w-20 h-20 bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20100%22%3E%3Cpath%20d%3D%22M100%200%20L0%200%20L100%20100%22%20fill%3D%22%23e53e3e%22%20opacity%3D%220.3%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
              </div>
            </div>

            {/* Right - Info */}
            <div className="animate-fade-in-up stagger-2">
              <p className="text-[#e53e3e] text-xs font-bold tracking-[0.3em] uppercase mb-4">
                LATEST RELEASE
              </p>
              <h2 className="text-white text-3xl md:text-4xl font-black tracking-tight mb-2" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                STUDIOBOOK PLATFORM
              </h2>
              <p className="text-gray-400 text-lg mb-6">
                The New Platform
              </p>
              <p className="text-gray-400 text-sm leading-relaxed mb-8">
                Platform terbaru kami adalah perjalanan tentang menemukan, memesan, dan mengelola studio rekaman profesional — semuanya dalam satu tempat.
              </p>

              {/* Platform links */}
              <div className="flex flex-wrap gap-3 mb-8">
                <span className="px-4 py-2 rounded-full bg-[#1DB954]/20 text-[#1DB954] text-sm font-semibold border border-[#1DB954]/30">
                  🎵 Spotify
                </span>
                <span className="px-4 py-2 rounded-full bg-[#FF0000]/20 text-[#FF0000] text-sm font-semibold border border-[#FF0000]/30">
                  ▶ YouTube
                </span>
                <span className="px-4 py-2 rounded-full bg-white/10 text-white text-sm font-semibold border border-white/20">
                  🍎 Apple Music
                </span>
              </div>

              {/* Audio player style */}
              <div className="bg-[#111] rounded-lg p-4 border border-white/5">
                <div className="flex items-center gap-4">
                  <button className="w-12 h-12 rounded-full bg-[#e53e3e] flex items-center justify-center text-white hover:bg-[#fc8181] transition-colors">
                    ▶
                  </button>
                  <div className="flex-1">
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-white text-sm font-semibold">StudioBook Platform</span>
                      <span className="text-text-muted text-xs">02:31 / 04:12</span>
                    </div>
                    <div className="h-1 bg-white/10 rounded-full overflow-hidden">
                      <div className="h-full bg-[#e53e3e] rounded-full" style={{ width: '60%' }} />
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Stats Section ═══ */}
      <section className="py-16 relative bg-[#050505]">
        <div className="max-w-6xl mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
            {stats.map((stat, i) => {
              const value = platformStats[stat.key] || 0
              return (
                <div key={stat.label} className={`text-center group animate-fade-in-up stagger-${i + 1}`}>
                  <p className="text-4xl md:text-5xl font-black text-[#e53e3e]">
                    {stat.key === 'average_rating' ? (
                      <AnimatedCounter target={Math.round(value * 10)} format={(n) => (n / 10).toFixed(1)} />
                    ) : (
                      <AnimatedCounter target={value} format={(n) => n.toLocaleString('id-ID')} />
                    )}
                  </p>
                  <p className="text-text-muted text-xs font-bold tracking-widest mt-2">{stat.label}</p>
                </div>
              )
            })}
          </div>
        </div>
      </section>

      {/* ═══ About Section ═══ */}
      <section id="about" className="py-24 relative bg-[#050505]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Left - Image */}
            <div className="relative animate-fade-in-up">
              <div className="aspect-[4/3] bg-gradient-to-br from-[#1a1a1a] to-[#0d0d0d] rounded-lg overflow-hidden border border-white/5 relative">
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="grid grid-cols-2 gap-4 p-8">
                    <div className="aspect-square bg-[#111] rounded-lg flex items-center justify-center border border-white/5">
                      <span className="text-4xl">🎸</span>
                    </div>
                    <div className="aspect-square bg-[#111] rounded-lg flex items-center justify-center border border-white/5">
                      <span className="text-4xl">🎹</span>
                    </div>
                    <div className="aspect-square bg-[#111] rounded-lg flex items-center justify-center border border-white/5">
                      <span className="text-4xl">🎚️</span>
                    </div>
                    <div className="aspect-square bg-[#111] rounded-lg flex items-center justify-center border border-white/5">
                      <span className="text-4xl">🎤</span>
                    </div>
                  </div>
                </div>
                {/* Red corner accent */}
                <div className="absolute bottom-0 left-0 w-20 h-20 bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20100%22%3E%3Cpath%20d%3D%22M0%20100%20L100%20100%20L0%200%22%20fill%3D%22%23e53e3e%22%20opacity%3D%220.3%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
              </div>
            </div>

            {/* Right - Content */}
            <div className="animate-fade-in-up stagger-2">
              <p className="text-[#e53e3e] text-xs font-bold tracking-[0.3em] uppercase mb-4">
                ABOUT THE PLATFORM
              </p>
              <h2 className="text-white text-3xl md:text-4xl font-black tracking-tight mb-4" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                Four people.<br />One sound.
              </h2>
              <p className="text-gray-400 text-sm leading-relaxed mb-8">
                StudioBook adalah platform untuk menemukan studio musik yang terbentuk pada tahun 2024. Dengan perpaduan teknologi yang kuat dan layanan yang jujur, kami ingin menyampaikan cerita tentang kehidupan, mimpi, dan harapan di tengah gelapnya dunia musik.
              </p>
              
              {/* Stats */}
              <div className="grid grid-cols-3 gap-6 mb-8">
                <div>
                  <p className="text-3xl font-black text-[#e53e3e]">
                    {platformStats.total_studios || '...'}+
                  </p>
                  <p className="text-text-muted text-xs font-bold tracking-widest mt-1">STUDIOS</p>
                </div>
                <div>
                  <p className="text-3xl font-black text-[#e53e3e]">
                    {platformStats.total_bookings || '...'}+
                  </p>
                  <p className="text-text-muted text-xs font-bold tracking-widest mt-1">BOOKINGS</p>
                </div>
                <div>
                  <p className="text-3xl font-black text-[#e53e3e]">
                    {platformStats.total_cities || '...'}
                  </p>
                  <p className="text-text-muted text-xs font-bold tracking-widest mt-1">CITIES</p>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-3">
                <Link to="/register" className="btn-red text-sm py-3 px-8 inline-flex items-center gap-2">
                  DAFTAR GRATIS <span>→</span>
                </Link>
                <Link to="/download" className="btn-glass text-sm py-3 px-8 inline-flex items-center gap-2">
                  DOWNLOAD APP <span className="text-[#e53e3e]">↓</span>
                </Link>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ═══ Upcoming Bookings Section ═══ */}
      <section id="upcoming" className="py-24 relative bg-[#050505]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-end justify-between mb-12">
            <div>
              <p className="text-[#e53e3e] text-xs font-bold tracking-[0.3em] uppercase mb-4">
                UPCOMING BOOKINGS
              </p>
              <h2 className="text-white text-3xl md:text-4xl font-black tracking-tight" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                Catch Us Live
              </h2>
            </div>
            <a href="#" className="text-[#e53e3e] text-sm font-semibold hover:underline hidden md:block">
              VIEW ALL EVENTS →
            </a>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {upcomingBookings.map((booking, i) => (
              <div
                key={i}
                className={`event-card p-6 animate-fade-in-up stagger-${i + 1}`}
              >
                {/* Date */}
                <div className="flex items-baseline gap-2 mb-4">
                  <span className="text-white text-4xl font-black">{booking.date}</span>
                  <div>
                    <span className="text-[#e53e3e] text-sm font-bold block">{booking.month}</span>
                    <span className="text-text-muted text-xs">{booking.year}</span>
                  </div>
                </div>

                {/* Studio info */}
                <h3 className="text-white font-bold text-lg mb-1">{booking.studio}</h3>
                <p className="text-[#e53e3e] text-sm font-semibold mb-2">{booking.type}</p>
                <p className="text-text-muted text-xs mb-4">📍 {booking.location}</p>

                {/* CTA */}
                <button className="w-full py-2.5 rounded bg-[#e53e3e] text-white text-sm font-bold hover:bg-[#fc8181] transition-colors">
                  BOOK NOW
                </button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ Gallery Section ═══ */}
      <section id="gallery" className="py-24 relative bg-[#050505]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex items-end justify-between mb-12">
            <div>
              <p className="text-[#e53e3e] text-xs font-bold tracking-[0.3em] uppercase mb-4">
                GALLERY
              </p>
              <h2 className="text-white text-3xl md:text-4xl font-black tracking-tight" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                Moments
              </h2>
            </div>
            <a href="#" className="text-[#e53e3e] text-sm font-semibold hover:underline hidden md:block">
              VIEW MORE →
            </a>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            {galleryImages.map((img, i) => (
              <div
                key={i}
                className={`aspect-square bg-gradient-to-br from-[#1a1a1a] to-[#0d0d0d] rounded-lg border border-white/5 flex flex-col items-center justify-center hover:border-[#e53e3e]/30 transition-all duration-300 group animate-fade-in-up stagger-${i + 1}`}
              >
                <span className="text-4xl mb-2 group-hover:scale-110 transition-transform">{img.icon}</span>
                <span className="text-text-muted text-xs font-semibold tracking-wider">{img.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══ CTA Section ═══ */}
      <section id="contact" className="py-24 relative bg-[#050505]">
        <div className="max-w-5xl mx-auto px-6 text-center">
          <p className="text-[#e53e3e] text-sm font-bold tracking-[0.3em] uppercase mb-4">
            READY TO HEAR US?
          </p>
          <h2 className="text-white text-3xl md:text-5xl font-black tracking-tight mb-8" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
            FOLLOW THE JOURNEY.
          </h2>
          
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a href="#" className="px-6 py-3 rounded-full bg-white/5 border border-white/10 text-white text-sm font-semibold hover:border-[#e53e3e]/50 hover:text-[#e53e3e] transition-all flex items-center gap-2">
              📷 INSTAGRAM
            </a>
            <a href="#" className="px-6 py-3 rounded-full bg-[#FF0000]/20 border border-[#FF0000]/30 text-[#FF0000] text-sm font-semibold hover:bg-[#FF0000]/30 transition-all flex items-center gap-2">
              ▶ YOUTUBE
            </a>
            <a href="#" className="px-6 py-3 rounded-full bg-[#1DB954]/20 border border-[#1DB954]/30 text-[#1DB954] text-sm font-semibold hover:bg-[#1DB954]/30 transition-all flex items-center gap-2">
              🎵 SPOTIFY
            </a>
          </div>
        </div>
      </section>

      {/* ═══ Footer ═══ */}
      <footer className="border-t border-white/5 py-12 relative bg-[#050505]">
        <div className="max-w-7xl mx-auto px-6">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            {/* Logo */}
            <div className="flex items-center gap-3">
              <span className="font-black text-xl tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
                STUDIO<span className="text-[#e53e3e]">BOOK</span>
              </span>
            </div>

            {/* Copyright */}
            <p className="text-text-muted text-xs">
              © 2026 StudioBook. All rights reserved.
            </p>

            {/* Links */}
            <div className="flex items-center gap-6">
              <a href="#" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Home</a>
              <a href="#featured" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Studios</a>
              <a href="#about" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">About</a>
              <a href="#upcoming" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Bookings</a>
              <a href="#gallery" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Gallery</a>
              <a href="#contact" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Contact</a>
              <Link to="/download" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Download App</Link>
              <Link to="/register" className="text-text-muted text-xs hover:text-[#e53e3e] transition-colors">Daftar</Link>
            </div>

            {/* Social */}
            <div className="flex items-center gap-3">
              <a href="#" className="w-8 h-8 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-text-muted hover:text-[#e53e3e] hover:border-[#e53e3e]/30 transition-all">
                <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z"/></svg>
              </a>
              <a href="#" className="w-8 h-8 rounded-full bg-white/5 border border-white/10 flex items-center justify-center text-text-muted hover:text-[#e53e3e] hover:border-[#e53e3e]/30 transition-all">
                <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 24 24"><path d="M19.615 3.184c-3.604-.246-11.631-.245-15.23 0-3.897.266-4.356 2.62-4.385 8.816.029 6.185.484 8.549 4.385 8.816 3.6.245 11.626.246 15.23 0 3.897-.266 4.356-2.62 4.385-8.816-.029-6.185-.484-8.549-4.385-8.816zm-10.615 12.816v-8l8 3.993-8 4.007z"/></svg>
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}
