import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'

export default function Login() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login } = useAuth()
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      await login(email, password)
      const userData = JSON.parse(localStorage.getItem('user') || '{}')
      switch (userData.role) {
        case 'owner':   navigate('/owner/dashboard'); break
        case 'customer': navigate('/customer/dashboard'); break
        case 'admin':
        case 'super_admin':
        default:         navigate('/'); break
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Login failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-primary relative overflow-hidden">
      {/* Ambient glow orbs */}
      <div className="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] bg-[radial-gradient(circle,rgba(212,175,55,0.06)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-[-15%] right-[-5%] w-[400px] h-[400px] bg-[radial-gradient(circle,rgba(212,175,55,0.04)_0%,transparent_70%)] rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md px-6 relative z-10">
        {/* Logo & branding */}
        <div className="text-center mb-10 animate-fade-in-up">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-gradient-to-br from-accent/20 to-accent/5 border border-accent/15 mb-5 animate-float">
            <span className="text-3xl">🎸</span>
          </div>
          <h1 className="text-4xl font-bold gold-text tracking-tight">StudioBook</h1>
          <p className="text-text-secondary mt-2 text-sm tracking-wide">Premium Music Studio Booking Platform</p>
        </div>

        {/* Login card */}
        <div className="glass-strong rounded-2xl p-8 luxury-shadow-lg animate-fade-in-up stagger-1">
          {/* Card header */}
          <div className="mb-8">
            <h2 className="text-xl font-semibold text-text-primary">Welcome back</h2>
            <p className="text-text-muted text-sm mt-1">Sign in to your account to continue</p>
          </div>

          {/* Error */}
          {error && (
            <div className="mb-6 p-3.5 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm flex items-center gap-2.5 animate-scale-in">
              <span className="text-base">⚠</span>
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email */}
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email Address</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="input-luxury w-full"
                placeholder="admin@studiobook.com"
                required
              />
            </div>

            {/* Password */}
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="input-luxury w-full"
                placeholder="••••••••"
                required
              />
            </div>

            {/* Remember & forgot */}
            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer group">
                <div className="relative">
                  <input type="checkbox" className="peer sr-only" />
                  <div className="w-4 h-4 rounded border border-border-light bg-surface-light peer-checked:bg-accent peer-checked:border-accent transition-all" />
                  <svg className="absolute inset-0 w-4 h-4 text-primary opacity-0 peer-checked:opacity-100 transition-opacity p-0.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                    <path d="M5 12l5 5L20 7" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                </div>
                <span className="text-text-secondary text-sm group-hover:text-text-primary transition-colors">Remember me</span>
              </label>
              <a href="#" className="text-accent text-sm hover:text-accent-hover transition-colors">
                Forgot password?
              </a>
            </div>

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="btn-gold w-full py-3 text-sm font-semibold tracking-wide disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Signing in...
                </span>
              ) : 'Sign In'}
            </button>
          </form>

          {/* Divider */}
          <div className="my-7">
            <div className="divider-gold" />
          </div>

          {/* Demo accounts */}
          <div>
            <p className="text-text-muted text-xs text-center mb-4 tracking-wide uppercase font-medium">Quick Access</p>
            <div className="space-y-2.5">
              {[
                { email: 'admin@studiobook.com', role: 'Super Admin', color: 'text-accent' },
                { email: 'owner@studiobook.com', role: 'Owner', color: 'text-success' },
                { email: 'customer@studiobook.com', role: 'Customer', color: 'text-info' },
              ].map((account) => (
                <button
                  key={account.email}
                  onClick={() => { setEmail(account.email); setPassword('password') }}
                  className="w-full flex items-center justify-between px-3.5 py-2.5 bg-surface-light/50 border border-border/50 rounded-xl hover:border-accent/20 hover:bg-surface-lighter/50 transition-all text-sm group cursor-pointer"
                >
                  <span className="font-mono text-text-secondary group-hover:text-text-primary transition-colors text-xs">{account.email}</span>
                  <span className={`text-xs font-medium ${account.color}`}>{account.role}</span>
                </button>
              ))}
              <p className="text-text-muted text-center text-xs pt-1">Password: <span className="font-mono text-text-secondary">password</span></p>
            </div>
          </div>
        </div>

        {/* Footer */}
        <p className="text-center text-text-muted text-xs mt-8 tracking-wide">
          © 2025 StudioBook. Crafted with ♪
        </p>
      </div>
    </div>
  )
}
