import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import GoogleSignInButton from '../../components/GoogleSignInButton'
import { describeAuthError } from '../../utils/authErrors'

// Client ID OAuth (Web) dari Google Cloud Console.
const GOOGLE_CLIENT_ID = import.meta.env.VITE_GOOGLE_CLIENT_ID || ''

/**
 * Pendaftaran akun **customer**.
 *
 * Akun owner tidak dibuat dari sini — backend hanya membuat role customer
 * (lihat AuthController@register). Akun owner dibuat oleh admin.
 */
export default function Register() {
  const [name, setName] = useState('')
  const [email, setEmail] = useState('')
  const [phone, setPhone] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { register, loginWithGoogle } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')

    if (password.length < 8) {
      setError('Password minimal 8 karakter.')
      return
    }

    if (password !== confirmPassword) {
      setError('Konfirmasi password tidak cocok.')
      return
    }

    setLoading(true)

    try {
      await register(name.trim(), email.trim(), password, phone.trim() || undefined)
      navigate('/customer/dashboard')
    } catch (err) {
      console.error('[Register Error]', err)
      setError(describeAuthError(err, 'Pendaftaran gagal. Silakan coba lagi.'))
    } finally {
      setLoading(false)
    }
  }

  const handleGoogleCredential = async (idToken: string) => {
    setError('')
    setLoading(true)

    try {
      // Akun Google baru selalu dibuat sebagai customer.
      await loginWithGoogle(idToken, 'customer')
      navigate('/customer/dashboard')
    } catch (err) {
      console.error('[Google Register Error]', err)
      setError(describeAuthError(err, 'Pendaftaran dengan Google gagal. Silakan coba lagi.'))
    } finally {
      setLoading(false)
    }
  }

  const inputClass =
    'w-full px-4 py-3 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors'

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#050505] relative overflow-hidden py-12">
      {/* Ambient glow orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(229,62,62,0.08)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-[-15%] right-[-5%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(229,62,62,0.06)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md px-6 relative z-10">
        {/* Logo & branding */}
        <div className="text-center mb-10 animate-fade-in-up">
          <Link to="/" className="inline-block">
            <span
              className="font-black text-4xl tracking-tight text-white"
              style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
            >
              STUDIO<span className="text-[#e53e3e]">BOOK</span>
            </span>
          </Link>
          <p className="text-gray-500 mt-3 text-sm tracking-widest uppercase">
            MUSIC THAT SPEAKS LOUDER
          </p>
        </div>

        <div className="bg-[#0d0d0d] rounded-lg p-8 border border-white/5 animate-fade-in-up stagger-1">
          <div className="mb-8">
            <h2
              className="text-white text-xl font-bold tracking-tight"
              style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
            >
              DAFTAR AKUN
            </h2>
            <p className="text-gray-500 text-sm mt-2">
              Buat akun customer untuk booking studio favoritmu
            </p>
          </div>

          {/* Info: akun owner dibuat admin */}
          <div className="mb-6 p-3.5 bg-[#63b3ed]/10 border border-[#63b3ed]/20 rounded text-[#63b3ed] text-xs flex items-start gap-2.5">
            <span className="text-base leading-none">ℹ</span>
            <span>
              Akun pemilik studio (owner) dibuat oleh admin. Hubungi admin bila ingin
              mendaftarkan studio Anda.
            </span>
          </div>

          {error && (
            <div className="mb-6 p-3.5 bg-[#e53e3e]/10 border border-[#e53e3e]/20 rounded text-[#e53e3e] text-sm flex items-center gap-2.5 animate-scale-in">
              <span className="text-base">⚠</span>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                NAMA LENGKAP
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className={inputClass}
                placeholder="Nama kamu"
                minLength={2}
                required
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                EMAIL ADDRESS
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={inputClass}
                placeholder="nama@email.com"
                required
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                NO. TELEPON <span className="text-gray-600 normal-case tracking-normal">(opsional)</span>
              </label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className={inputClass}
                placeholder="08123456789"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                PASSWORD
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={inputClass}
                placeholder="Minimal 8 karakter"
                minLength={8}
                required
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                ULANGI PASSWORD
              </label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className={inputClass}
                placeholder="••••••••"
                minLength={8}
                required
              />
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3.5 bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white font-bold text-sm tracking-widest rounded hover:from-[#e53e3e] hover:to-[#fc8181] transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-[#e53e3e]/20"
            >
              {loading ? 'MEMPROSES...' : 'DAFTAR'}
            </button>
          </form>

          <div className="my-8 flex items-center gap-4">
            <div className="flex-1 h-px bg-white/5" />
            <span className="text-gray-600 text-xs font-semibold tracking-widest">ATAU</span>
            <div className="flex-1 h-px bg-white/5" />
          </div>

          <GoogleSignInButton
            clientId={GOOGLE_CLIENT_ID}
            onCredential={handleGoogleCredential}
            onError={setError}
            text="signup_with"
          />

          <p className="text-center text-gray-500 text-sm mt-8">
            Sudah punya akun?{' '}
            <Link to="/login" className="text-[#e53e3e] hover:text-[#fc8181] transition-colors font-semibold">
              Masuk di sini
            </Link>
          </p>
        </div>

        <div className="mt-8 text-center">
          <Link to="/" className="text-gray-500 text-xs hover:text-[#e53e3e] transition-colors">
            ← Kembali ke Beranda
          </Link>
        </div>
      </div>
    </div>
  )
}
