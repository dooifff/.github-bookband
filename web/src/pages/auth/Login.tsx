import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import GoogleSignInButton from '../../components/GoogleSignInButton'
import { describeAuthError } from '../../utils/authErrors'

// Client ID OAuth (Web) dari Google Cloud Console.
const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || ''

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login, loginWithGoogle } = useAuth()
  const navigate = useNavigate()

  const navigateByRole = (role?: string) => {
    switch (role) {
      case 'owner':        navigate('/owner/dashboard'); break
      case 'customer':     navigate('/customer/dashboard'); break
      case 'admin':
      case 'super_admin':  navigate('/admin'); break
      default:             navigate('/'); break
    }
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
      const userData = JSON.parse(localStorage.getItem('user') || '{}')
      navigateByRole(userData.role)
    } catch (err) {
      console.error('[Login Error]', err)
      setError(describeAuthError(err, 'Email atau password tidak sesuai.'))
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleCredential = async (idToken: string) => {
    setError('')
    setLoading(true)

    try {
      const userData = await loginWithGoogle(idToken)
      navigateByRole(userData.role)
    } catch (err) {
      console.error('[Google Login Error]', err)
      setError(describeAuthError(err, 'Login dengan Google gagal. Silakan coba lagi.'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#050505] relative overflow-hidden">
      {/* Red brush stroke effect - left */}
      <div className="absolute top-0 left-0 w-[200px] h-full opacity-20 pointer-events-none">
        <div className="absolute top-[20%] left-0 w-[150px] h-[400px] bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20400%22%3E%3Cpath%20d%3D%22M0%200%20C20%2080%2080%20160%2030%20240%20C-10%20320%2060%20380%2020%20400%22%20stroke%3D%22%23e53e3e%22%20stroke-width%3D%226%22%20fill%3D%22none%22%20stroke-linecap%3D%22round%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
      </div>

      {/* Red brush stroke effect - right */}
      <div className="absolute top-0 right-0 w-[200px] h-full opacity-20 pointer-events-none">
        <div className="absolute top-[25%] right-0 w-[150px] h-[400px] bg-[url('data:image/svg+xml,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20viewBox%3D%220%200%20100%20400%22%3E%3Cpath%20d%3D%22M100%200%20C80%2080%2020%20160%2070%20240%20C110%20320%2040%20380%2080%20400%22%20stroke%3D%22%23e53e3e%22%20stroke-width%3D%226%22%20fill%3D%22none%22%20stroke-linecap%3D%22round%22%2F%3E%3C%2Fsvg%3E')] bg-no-repeat bg-contain" />
      </div>

      {/* Ambient glow orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(229,62,62,0.08)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-[-15%] right-[-5%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(229,62,62,0.06)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md px-6 relative z-10">
        {/* Logo & branding */}
        <div className="text-center mb-10 animate-fade-in-up">
          <Link to="/" className="inline-block">
            <span className="font-black text-4xl tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
              STUDIO<span className="text-[#e53e3e]">BOOK</span>
            </span>
          </Link>
          <p className="text-gray-500 mt-3 text-sm tracking-widest uppercase">
            MUSIC THAT SPEAKS LOUDER
          </p>
        </div>

        {/* Login card */}
        <div className="bg-[#0d0d0d] rounded-lg p-8 border border-white/5 animate-fade-in-up stagger-1">
          {/* Card header */}
          <div className="mb-8">
            <h2 className="text-white text-xl font-bold tracking-tight" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
              WELCOME BACK
            </h2>
            <p className="text-gray-500 text-sm mt-2">
              Masuk ke akun Anda untuk melanjutkan
            </p>
          </div>

          {/* Error */}
          {error && (
            <div className="mb-6 p-3.5 bg-[#e53e3e]/10 border border-[#e53e3e]/20 rounded text-[#e53e3e] text-sm flex items-center gap-2.5 animate-scale-in">
              <span className="text-base">⚠</span>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                EMAIL ADDRESS
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
                placeholder="admin@studiobook.com"
                required
              />
            </div>

            {/* Password */}
            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                PASSWORD
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-3 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
                placeholder="••••••••"
                required
              />
            </div>

            {/* Remember & forgot */}
            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer group">
                <div className="relative">
                  <input type="checkbox" className="peer sr-only" />
                  <div className="w-4 h-4 rounded border border-white/10 bg-[#111] peer-checked:bg-[#e53e3e] peer-checked:border-[#e53e3e] transition-all" />
                  <svg className="absolute inset-0 w-4 h-4 text-white opacity-0 peer-checked:opacity-100 transition-opacity p-0.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                    <path d="M5 12l5 5L20 7" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <span className="text-gray-400 text-sm group-hover:text-white transition-colors">Ingat saya</span>
              </label>
              <Link to="/forgot-password" className="text-[#e53e3e] text-sm hover:text-[#fc8181] transition-colors">
                Lupa password?
              </Link>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white font-bold text-sm tracking-widest rounded hover:from-[#e53e3e] hover:to-[#fc8181] transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-[#e53e3e]/20"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  MEMPROSES...
                </span>
              ) : 'MASUK'}
            </button>
          </form>

          {/* Daftar akun baru */}
          <p className="text-center text-gray-500 text-sm mt-6">
            Belum punya akun?{' '}
            <Link to="/register" className="text-[#e53e3e] hover:text-[#fc8181] transition-colors font-semibold">
              Daftar gratis
            </Link>
          </p>

          {/* Divider */}
          <div className="my-8 flex items-center gap-4">
            <div className="flex-1 h-px bg-white/5" />
            <span className="text-gray-600 text-xs font-semibold tracking-widest">ATAU</span>
            <div className="flex-1 h-px bg-white/5" />
          </div>

          {/* Google Sign-In - akun baru otomatis dibuat bila email belum terdaftar */}
          <GoogleSignInButton
            clientId={GOOGLE_CLIENT_ID}
            onCredential={handleGoogleCredential}
            onError={setError}
          />

          {/* Demo accounts */}
          <div>
            <p className="text-gray-600 text-xs text-center mb-4 tracking-widest uppercase font-semibold">
              AKSES CEPAT
            </p>
            <div className="space-y-2.5">
              {[
                { email: 'admin@studiobook.com', role: 'Super Admin', color: 'text-[#e53e3e]' },
                { email: 'owner@studiobook.com', role: 'Pemilik', color: 'text-[#48bb78]' },
                { email: 'customer@studiobook.com', role: 'Pelanggan', color: 'text-[#63b3ed]' },
              ].map((account) => (
                <button
                  key={account.email}
                  onClick={() => { setEmail(account.email); setPassword('password') }}
                  className="w-full flex items-center justify-between px-4 py-3 bg-[#111] border border-white/5 rounded hover:border-[#e53e3e]/20 hover:bg-[#151515] transition-all text-sm group cursor-pointer"
                >
                  <span className="font-mono text-gray-500 group-hover:text-white transition-colors text-xs">{account.email}</span>
                  <span className={`text-xs font-semibold ${account.color}`}>{account.role}</span>
                </button>
              ))}
              <p className="text-gray-600 text-center text-xs pt-2">
                Password: <span className="font-mono text-gray-400">password</span>
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="mt-8 text-center">
          <p className="text-gray-600 text-xs tracking-wide">
            © 2026 StudioBook. All rights reserved.
          </p>
          <Link to="/" className="text-gray-500 text-xs hover:text-[#e53e3e] transition-colors mt-2 inline-block">
            ← Kembali ke Beranda
          </Link>
          <span className="text-gray-700 text-xs mx-2">•</span>
          <Link to="/download" className="text-gray-500 text-xs hover:text-[#e53e3e] transition-colors mt-2 inline-block">
            Unduh aplikasi Android
          </Link>
        </div>
      </div>
    </div>
  )
}
