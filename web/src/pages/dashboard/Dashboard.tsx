import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface DashboardStats {
  total_users: number
  total_studios: number
  total_bookings: number
  total_revenue: number
  recent_bookings: any[]
  recent_users: any[]
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const fetchDashboard = useCallback(async () => {
    try {
      setLoading(true)
      setError('')
      const response = await api.get('/admin/dashboard')
      setStats(response.data.data)
    } catch (err: any) {
      console.error('Failed to fetch dashboard:', err)
      setError(err.response?.data?.message || 'Failed to load dashboard')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchDashboard() }, [fetchDashboard])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const statCards = [
    { title: 'Total Pengguna', value: stats?.total_users || 0, icon: '👥', accent: 'from-blue-500/15 to-blue-500/5', iconBg: 'bg-blue-500/10' },
    { title: 'Total Studio', value: stats?.total_studios || 0, icon: '🏠', accent: 'from-success/15 to-success/5', iconBg: 'bg-success/10' },
    { title: 'Total Pemesanan', value: stats?.total_bookings || 0, icon: '📅', accent: 'from-purple-500/15 to-purple-500/5', iconBg: 'bg-purple-500/10' },
    { title: 'Total Pendapatan', value: formatCurrency(stats?.total_revenue || 0), icon: '💰', accent: 'from-accent/15 to-accent/5', iconBg: 'bg-accent/10' },
  ]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat dasbor...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <p className="text-danger mb-4">{error}</p>
            <button onClick={fetchDashboard} className="btn-gold text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-8">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Dashboard</h1>
          <p className="text-text-secondary mt-1 text-sm">Selamat datang kembali! Berikut yang terjadi hari ini.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {statCards.map((stat, i) => (
            <div key={stat.title} className={`card-luxury p-6 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-text-muted text-xs font-medium tracking-wide uppercase">{stat.title}</p>
                  <p className="text-2xl font-bold text-text-primary mt-2 tracking-tight">{stat.value}</p>
                </div>
                <div className={`w-11 h-11 rounded-xl ${stat.iconBg} flex items-center justify-center text-lg`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Bookings */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-5">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Pemesanan Terbaru</h2>
              <a href="/bookings" className="text-accent text-xs font-medium hover:text-accent-hover transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1">
              {stats?.recent_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-surface-lighter flex items-center justify-center text-sm">
                      {booking.user?.name?.charAt(0) || 'U'}
                    </div>
                    <div>
                      <p className="text-text-primary text-sm font-medium">{booking.user?.name || 'User'}</p>
                      <p className="text-text-muted text-xs">{booking.studio?.name || 'Studio'}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-block px-2 py-0.5 text-[0.65rem] font-medium rounded-full ${
                      booking.status === 'confirmed' ? 'bg-success/10 text-success' :
                      booking.status === 'pending' ? 'bg-warning/10 text-warning' :
                      'bg-text-muted/10 text-text-muted'
                    }`}>{booking.status}</span>
                    <p className="text-text-muted text-xs mt-0.5">{formatCurrency(booking.total_amount)}</p>
                  </div>
                </div>
              ))}
              {(!stats?.recent_bookings || stats.recent_bookings.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">Tidak ada pemesanan terbaru</p>
              )}
            </div>
          </div>

          {/* Recent Users */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Pengguna Terbaru</h2>
              <a href="/users" className="text-accent text-xs font-medium hover:text-accent-hover transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1">
              {stats?.recent_users?.slice(0, 5).map((user) => (
                <div key={user.id} className="flex items-center gap-3 py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/15 to-accent/5 flex items-center justify-center border border-accent/10">
                    <span className="text-accent text-xs font-semibold">{user.name?.charAt(0)}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-text-primary text-sm font-medium truncate">{user.name}</p>
                    <p className="text-text-muted text-xs truncate">{user.email}</p>
                  </div>
                  <span className={`px-2 py-0.5 text-[0.65rem] font-medium rounded-full ${
                    user.role === 'admin' ? 'bg-accent/10 text-accent' :
                    user.role === 'owner' ? 'bg-success/10 text-success' :
                    'bg-text-muted/10 text-text-muted'
                  }`}>{user.role}</span>
                </div>
              ))}
              {(!stats?.recent_users || stats.recent_users.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">Tidak ada pengguna terbaru</p>
              )}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-7">
          <h2 className="text-base font-semibold text-text-primary mb-5">Aksi Cepat</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { href: '/users', icon: '👥', label: 'Kelola Pengguna' },
              { href: '/studios', icon: '🏠', label: 'Kelola Studio' },
              { href: '/bookings', icon: '📅', label: 'Lihat Pemesanan' },
              { href: '/settings', icon: '⚙️', label: 'Pengaturan' },
            ].map((action) => (
              <a
                key={action.href}
                href={action.href}
                className="group flex flex-col items-center gap-3 p-5 rounded-xl bg-surface-light/50 border border-border/50 hover:border-accent/20 hover:bg-surface-lighter/40 transition-all duration-300"
              >
                <span className="text-2xl group-hover:scale-110 transition-transform duration-300">{action.icon}</span>
                <span className="text-text-secondary text-sm font-medium group-hover:text-text-primary transition-colors">{action.label}</span>
              </a>
            ))}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
