import { useState } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import { useAuth } from '../../hooks/useAuth'
import api from '../../services/api'

export default function SettingsPage() {
  const { user, updateUser } = useAuth()
  const [name, setName] = useState(user?.name || '')
  const [email, setEmail] = useState(user?.email || '')
  const [phone, setPhone] = useState(user?.phone || '')
  const [currentPassword, setCurrentPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [message, setMessage] = useState('')
  const [error, setError] = useState('')

  const handleUpdateProfile = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setMessage('')
    setError('')
    try {
      const response = await api.put('/auth/profile', { name, email, phone })
      updateUser(response.data.data)
      setMessage('Profile updated successfully!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update profile')
    } finally {
      setLoading(false)
    }
  }

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (newPassword !== confirmPassword) {
      setError('Passwords do not match')
      return
    }
    setLoading(true)
    setMessage('')
    setError('')
    try {
      await api.put('/auth/password', {
        current_password: currentPassword,
        password: newPassword,
        password_confirmation: confirmPassword,
      })
      setMessage('Password updated successfully!')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to update password')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-8 max-w-2xl">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Settings</h1>
          <p className="text-text-secondary mt-1 text-sm">Manage your account settings</p>
        </div>

        {/* Messages */}
        {message && (
          <div className="p-4 bg-success/8 border border-success/20 rounded-xl text-success text-sm flex items-center gap-2 animate-scale-in">
            <span>✓</span> {message}
          </div>
        )}
        {error && (
          <div className="p-4 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm flex items-center gap-2 animate-scale-in">
            <span>⚠</span> {error}
          </div>
        )}

        {/* Profile */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-1">
          <h2 className="text-base font-semibold text-text-primary mb-5">Profile</h2>
          <form onSubmit={handleUpdateProfile} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Name</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Phone</label>
              <input type="text" value={phone} onChange={(e) => setPhone(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <button type="submit" disabled={loading} className="btn-gold text-sm disabled:opacity-40">
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
          </form>
        </div>

        {/* Password */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-2">
          <h2 className="text-base font-semibold text-text-primary mb-5">Change Password</h2>
          <form onSubmit={handleUpdatePassword} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Current Password</label>
              <input type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">New Password</label>
              <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Confirm New Password</label>
              <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <button type="submit" disabled={loading} className="btn-gold text-sm disabled:opacity-40">
              {loading ? 'Updating...' : 'Update Password'}
            </button>
          </form>
        </div>

        {/* Account Info */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-3">
          <h2 className="text-base font-semibold text-text-primary mb-5">Account Info</h2>
          <div className="space-y-0">
            <div className="flex justify-between py-3 border-b border-border/40">
              <span className="text-text-muted text-sm">Role</span>
              <span className="text-text-primary text-sm font-medium capitalize">{user?.role}</span>
            </div>
            <div className="flex justify-between py-3">
              <span className="text-text-muted text-sm">Member Since</span>
              <span className="text-text-primary text-sm">{user?.id ? `User #${user.id}` : '-'}</span>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
