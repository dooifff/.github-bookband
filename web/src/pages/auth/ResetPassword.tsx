import { useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import { describeAuthError } from '../../utils/authErrors'

/**
 * Menyelesaikan reset password.
 *
 * Dibuka dari tautan email: `/reset-password?token=..&email=..`
 */
export default function ResetPassword() {
  const [searchParams] = useSearchParams()
  const [token, setToken] = useState(searchParams.get('token') || '')
  const [email, setEmail] = useState(searchParams.get('email') || '')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)
  const { resetPassword } = useAuth()
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
      await resetPassword(token.trim(), email.trim(), password)
      setDone(true)
      setTimeout(() => navigate('/login'), 2500)
    } catch (err) {
      console.error('[Reset Password Error]', err)
      setError(describeAuthError(err, 'Gagal mengatur ulang password.'))
    } finally {
      setLoading(false)
    }
  }

  const inputClass =
    'w-full px-4 py-3 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors'

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#050505] relative overflow-hidden py-12">
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(229,62,62,0.08)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md px-6 relative z-10">
        <div className="text-center mb-10 animate-fade-in-up">
          <Link to="/" className="inline-block">
            <span
              className="font-black text-4xl tracking-tight text-white"
              style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
            >
              STUDIO<span className="text-[#e53e3e]">BOOK</span>
            </span>
          </Link>
        </div>

        <div className="bg-[#0d0d0d] rounded-lg p-8 border border-white/5 animate-fade-in-up stagger-1">
          {done ? (
            <div className="text-center space-y-4">
              <div className="w-16 h-16 mx-auto rounded-full bg-[#48bb78]/10 flex items-center justify-center">
                <span className="text-3xl">✓</span>
              </div>
              <h2
                className="text-white text-xl font-bold tracking-tight"
                style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
              >
                PASSWORD DIUBAH
              </h2>
              <p className="text-gray-500 text-sm">
                Password baru sudah aktif. Kamu akan diarahkan ke halaman login...
              </p>
              <Link
                to="/login"
                className="inline-block w-full py-3.5 bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white font-bold text-sm tracking-widest rounded text-center"
              >
                LOGIN SEKARANG
              </Link>
            </div>
          ) : (
            <>
              <div className="mb-8">
                <h2
                  className="text-white text-xl font-bold tracking-tight"
                  style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
                >
                  PASSWORD BARU
                </h2>
                <p className="text-gray-500 text-sm mt-2">
                  Tempel token dari email beserta password baru kamu.
                </p>
              </div>

              {error && (
                <div className="mb-6 p-3.5 bg-[#e53e3e]/10 border border-[#e53e3e]/20 rounded text-[#e53e3e] text-sm flex items-center gap-2.5">
                  <span className="text-base">⚠</span>
                  {error}
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-5">
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
                    TOKEN RESET
                  </label>
                  <input
                    type="text"
                    value={token}
                    onChange={(e) => setToken(e.target.value)}
                    className={`${inputClass} font-mono`}
                    placeholder="Token dari email"
                    required
                  />
                </div>

                <div className="space-y-1.5">
                  <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">
                    PASSWORD BARU
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
                  {loading ? 'MENYIMPAN...' : 'SIMPAN PASSWORD'}
                </button>
              </form>

              <p className="text-center text-gray-500 text-sm mt-8">
                Belum punya token?{' '}
                <Link
                  to="/forgot-password"
                  className="text-[#e53e3e] hover:text-[#fc8181] transition-colors font-semibold"
                >
                  Minta tautan reset
                </Link>
              </p>
            </>
          )}
        </div>
      </div>
    </div>
  )
}
