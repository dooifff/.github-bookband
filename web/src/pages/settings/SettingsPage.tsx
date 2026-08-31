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
      setMessage('Profil berhasil diperbarui!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Gagal memperbarui profil')
    } finally {
      setLoading(false)
    }
  }

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (newPassword !== confirmPassword) {
      setError('Kata sandi tidak cocok')
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
      setMessage('Kata sandi berhasil diperbarui!')
      setCurrentPassword('')
      setNewPassword('')
      setConfirmPassword('')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Gagal memperbarui kata sandi')
    } finally {
      setLoading(false)
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-8 max-w-2xl">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Pengaturan</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola pengaturan akun Anda</p>
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
          <h2 className="text-base font-semibold text-text-primary mb-5">Profil</h2>
          <form onSubmit={handleUpdateProfile} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama</label>
              <input type="text" value={name} onChange={(e) => setName(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
              <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Telepon</label>
              <input type="text" value={phone} onChange={(e) => setPhone(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <button type="submit" disabled={loading} className="btn-gold text-sm disabled:opacity-40">
              {loading ? 'Menyimpan...' : 'Simpan Perubahan'}
            </button>
          </form>
        </div>

        {/* Password */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-2">
          <h2 className="text-base font-semibold text-text-primary mb-5">Ubah Kata Sandi</h2>
          <form onSubmit={handleUpdatePassword} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kata Sandi Saat Ini</label>
              <input type="password" value={currentPassword} onChange={(e) => setCurrentPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kata Sandi Baru</label>
              <input type="password" value={newPassword} onChange={(e) => setNewPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <div className="space-y-1.5">
              <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Konfirmasi Kata Sandi Baru</label>
              <input type="password" value={confirmPassword} onChange={(e) => setConfirmPassword(e.target.value)} className="input-luxury w-full text-sm" />
            </div>
            <button type="submit" disabled={loading} className="btn-gold text-sm disabled:opacity-40">
              {loading ? 'Memperbarui...' : 'Perbarui Kata Sandi'}
            </button>
          </form>
        </div>

        {/* Account Info */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-3">
          <h2 className="text-base font-semibold text-text-primary mb-5">Info Akun</h2>
          <div className="space-y-0">
            <div className="flex justify-between py-3 border-b border-border/40">
              <span className="text-text-muted text-sm">Peran</span>
              <span className="text-text-primary text-sm font-medium capitalize">{user?.role}</span>
            </div>
            <div className="flex justify-between py-3">
              <span className="text-text-muted text-sm">Anggota Sejak</span>
              <span className="text-text-primary text-sm">{user?.id ? `Pengguna #${user.id}` : '-'}</span>
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
