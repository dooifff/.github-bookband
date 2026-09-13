import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import { describeAuthError } from '../../utils/authErrors'

/**
 * Meminta tautan reset password.
 *
 * Backend mengirim email berisi tautan ke `/reset-password?token=..&email=..`.
 * Ia selalu membalas sukses, walau email belum terdaftar, supaya tidak
 * membocorkan daftar pengguna.
 */
export default function ForgotPassword() {
  const [email, setEmail] = useState('')
  const [sent, setSent] = useState(false)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { requestPasswordReset } = useAuth()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await requestPasswordReset(email.trim())
      setSent(true)
    } catch (err) {
      console.error('[Forgot Password Error]', err)
      setError(describeAuthError(err, 'Gagal mengirim tautan reset password.'))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#050505] relative overflow-hidden">
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
          {sent ? (
            <div className="text-center space-y-5">
              <div className="w-16 h-16 mx-auto rounded-full bg-[#48bb78]/10 flex items-center justify-center">
                <span className="text-3xl">✉</span>
              </div>
              <div>
                <h2
                  className="text-white text-xl font-bold tracking-tight"
                  style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
                >
                  CEK EMAIL KAMU
                </h2>
                <p className="text-gray-500 text-sm mt-3 leading-relaxed">
                  Kalau <span className="text-gray-300">{email}</span> terdaftar, kami sudah
                  mengirim tautan untuk mengatur ulang password.
                </p>
              </div>
              <Link
                to="/login"
                className="inline-block w-full py-3.5 bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white font-bold text-sm tracking-widest rounded text-center"
              >
                KEMBALI KE LOGIN
              </Link>
              <p className="text-gray-600 text-xs">
                Punya token dari email?{' '}
                <Link to="/reset-password" className="text-[#e53e3e] hover:text-[#fc8181]">
                  Atur password baru
                </Link>
              </p>
            </div>
          ) : (
            <>
              <div className="mb-8">
                <h2
                  className="text-white text-xl font-bold tracking-tight"
                  style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}
                >
                  LUPA PASSWORD
                </h2>
                <p className="text-gray-500 text-sm mt-2">
                  Masukkan email akunmu, kami kirimkan tautan untuk mengatur ulang password.
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
                    className="w-full px-4 py-3 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
                    placeholder="nama@email.com"
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white font-bold text-sm tracking-widest rounded hover:from-[#e53e3e] hover:to-[#fc8181] transition-all disabled:opacity-40 disabled:cursor-not-allowed shadow-lg shadow-[#e53e3e]/20"
                >
                  {loading ? 'MENGIRIM...' : 'KIRIM TAUTAN RESET'}
                </button>
              </form>

              <p className="text-center text-gray-500 text-sm mt-8">
                Ingat passwordmu?{' '}
                <Link to="/login" className="text-[#e53e3e] hover:text-[#fc8181] transition-colors font-semibold">
                  Masuk
                </Link>
              </p>
            </>
          )}
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
