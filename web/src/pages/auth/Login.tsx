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
      // login() sets user in context, we need to read the role
      // After login, useAuth will have the user
      const userData = JSON.parse(localStorage.getItem('user') || '{}')

      // Redirect based on role
      switch (userData.role) {
        case 'owner':
          navigate('/owner/dashboard')
          break
        case 'customer':
          navigate('/customer/dashboard')
          break
        case 'admin':
        case 'super_admin':
        default:
          navigate('/')
          break
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Login failed. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-primary px-4">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-accent mb-2">🎸 StudioBook</h1>
          <p className="text-text-secondary">Music Studio Booking Platform</p>
        </div>

        {/* Login Card */}
        <div className="bg-surface border border-border rounded-xl p-8 shadow-lg">
          <h2 className="text-xl font-semibold text-text-primary mb-6">Sign In</h2>

          {error && (
            <div className="mb-4 p-3 bg-error/10 border border-error/30 rounded-lg text-error text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            <div>
              <label className="block text-text-secondary text-sm font-medium mb-2">
                Email Address
              </label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-3 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent transition-colors"
                placeholder="admin@studiobook.com"
                required
              />
            </div>

            <div>
              <label className="block text-text-secondary text-sm font-medium mb-2">
                Password
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-3 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent focus:ring-1 focus:ring-accent transition-colors"
                placeholder="••••••••"
                required
              />
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="w-4 h-4 accent-accent" />
                <span className="text-text-secondary text-sm">Remember me</span>
              </label>
              <a href="#" className="text-accent text-sm hover:underline">
                Forgot password?
              </a>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-accent hover:bg-accent-hover text-primary font-semibold py-3 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <svg className="animate-spin h-5 w-5" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                  </svg>
                  Signing in...
                </span>
              ) : (
                'Sign In'
              )}
            </button>
          </form>

          <div className="mt-6 pt-6 border-t border-border">
            <p className="text-text-muted text-sm text-center mb-3">Demo Accounts:</p>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between text-text-secondary">
                <span className="font-mono">admin@studiobook.com</span>
                <span className="text-text-muted">Super Admin</span>
              </div>
              <div className="flex justify-between text-text-secondary">
                <span className="font-mono">owner@studiobook.com</span>
                <span className="text-text-muted">Owner</span>
              </div>
              <div className="flex justify-between text-text-secondary">
                <span className="font-mono">customer@studiobook.com</span>
                <span className="text-text-muted">Customer</span>
              </div>
              <p className="text-text-muted text-center pt-2">Password: <span className="font-mono">password</span></p>
            </div>
          </div>
        </div>

        <p className="text-center text-text-muted text-sm mt-6">
          © 2025 StudioBook. All rights reserved.
        </p>
      </div>
    </div>
  )
}
