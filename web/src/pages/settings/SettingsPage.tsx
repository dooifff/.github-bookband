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
      <div className="space-y-6 max-w-2xl">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Settings</h1>
          <p className="text-text-secondary">Manage your account settings</p>
        </div>

        {message && (
          <div className="p-4 bg-success/10 border border-success/30 rounded-lg text-success">
            {message}
          </div>
        )}

        {error && (
          <div className="p-4 bg-error/10 border border-error/30 rounded-lg text-error">
            {error}
          </div>
        )}

        {/* Profile Section */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Profile</h2>
          <form onSubmit={handleUpdateProfile} className="space-y-4">
            <div>
              <label className="block text-text-secondary text-sm mb-2">Name</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="block text-text-secondary text-sm mb-2">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="block text-text-secondary text-sm mb-2">Phone</label>
              <input
                type="text"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="bg-accent hover:bg-accent-hover text-primary font-semibold px-6 py-2 rounded-lg transition-colors disabled:opacity-50"
            >
              {loading ? 'Saving...' : 'Save Changes'}
            </button>
          </form>
        </div>

        {/* Password Section */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Change Password</h2>
          <form onSubmit={handleUpdatePassword} className="space-y-4">
            <div>
              <label className="block text-text-secondary text-sm mb-2">Current Password</label>
              <input
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="block text-text-secondary text-sm mb-2">New Password</label>
              <input
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <div>
              <label className="block text-text-secondary text-sm mb-2">Confirm New Password</label>
              <input
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="bg-accent hover:bg-accent-hover text-primary font-semibold px-6 py-2 rounded-lg transition-colors disabled:opacity-50"
            >
              {loading ? 'Updating...' : 'Update Password'}
            </button>
          </form>
        </div>

        {/* Account Info */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Account Info</h2>
          <div className="space-y-3">
            <div className="flex justify-between py-2 border-b border-border">
              <span className="text-text-muted">Role</span>
              <span className="text-text-primary font-medium capitalize">{user?.role}</span>
            </div>
            <div className="flex justify-between py-2 border-b border-border">
              <span className="text-text-muted">Member Since</span>
              <span className="text-text-primary">{user?.id ? `User #${user.id}` : '-'}</span>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
