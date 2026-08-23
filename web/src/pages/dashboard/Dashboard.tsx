import { useState, useEffect } from 'react'
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

  useEffect(() => {
    fetchDashboard()
  }, [])

  const fetchDashboard = async () => {
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
  }

  const statCards = [
    { title: 'Total Users', value: stats?.total_users || 0, icon: '👥', color: 'bg-blue-500/10 text-blue-500' },
    { title: 'Total Studios', value: stats?.total_studios || 0, icon: '🏠', color: 'bg-green-500/10 text-green-500' },
    { title: 'Total Bookings', value: stats?.total_bookings || 0, icon: '📅', color: 'bg-purple-500/10 text-purple-500' },
    { title: 'Total Revenue', value: formatCurrency(stats?.total_revenue || 0), icon: '💰', color: 'bg-amber-500/10 text-amber-500' },
  ]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading dashboard...</div>
        </div>
      </AdminLayout>
    )
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <p className="text-error mb-4">{error}</p>
            <button
              onClick={fetchDashboard}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              Retry
            </button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Dashboard</h1>
          <p className="text-text-secondary">Welcome back! Here's what's happening.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {statCards.map((stat) => (
            <div key={stat.title} className="bg-surface border border-border rounded-xl p-6 hover:shadow-lg transition-shadow">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-text-muted text-sm">{stat.title}</p>
                  <p className="text-2xl font-bold text-text-primary mt-1">{stat.value}</p>
                </div>
                <div className={`w-12 h-12 rounded-lg flex items-center justify-center text-2xl ${stat.color}`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Recent Activity */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Recent Bookings */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">Recent Bookings</h2>
            <div className="space-y-3">
              {stats?.recent_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                  <div>
                    <p className="text-text-primary font-medium">{booking.user?.name || 'User'}</p>
                    <p className="text-text-muted text-sm">{booking.studio?.name || 'Studio'}</p>
                  </div>
                  <div className="text-right">
                    <span className={`px-2 py-1 text-xs rounded ${
                      booking.status === 'confirmed' ? 'bg-success/20 text-success' :
                      booking.status === 'pending' ? 'bg-warning/20 text-warning' :
                      'bg-text-muted/20 text-text-muted'
                    }`}>
                      {booking.status}
                    </span>
                    <p className="text-text-muted text-sm mt-1">{formatCurrency(booking.total_amount)}</p>
                  </div>
                </div>
              ))}
              {(!stats?.recent_bookings || stats.recent_bookings.length === 0) && (
                <p className="text-text-muted text-center py-4">No recent bookings</p>
              )}
            </div>
          </div>

          {/* Recent Users */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">Recent Users</h2>
            <div className="space-y-3">
              {stats?.recent_users?.slice(0, 5).map((user) => (
                <div key={user.id} className="flex items-center gap-3 py-2 border-b border-border last:border-0">
                  <div className="w-10 h-10 bg-accent/20 rounded-full flex items-center justify-center">
                    <span className="text-accent font-semibold">{user.name?.charAt(0)}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-text-primary font-medium truncate">{user.name}</p>
                    <p className="text-text-muted text-sm truncate">{user.email}</p>
                  </div>
                  <span className={`px-2 py-1 text-xs rounded ${
                    user.role === 'admin' ? 'bg-accent/20 text-accent' :
                    user.role === 'owner' ? 'bg-success/20 text-success' :
                    'bg-text-muted/20 text-text-muted'
                  }`}>
                    {user.role}
                  </span>
                </div>
              ))}
              {(!stats?.recent_users || stats.recent_users.length === 0) && (
                <p className="text-text-muted text-center py-4">No recent users</p>
              )}
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Quick Actions</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <a href="/users" className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left block">
              <span className="text-2xl mb-2 block">👥</span>
              <span className="text-text-primary font-medium">Manage Users</span>
            </a>
            <a href="/studios" className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left block">
              <span className="text-2xl mb-2 block">🏠</span>
              <span className="text-text-primary font-medium">Manage Studios</span>
            </a>
            <a href="/bookings" className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left block">
              <span className="text-2xl mb-2 block">📅</span>
              <span className="text-text-primary font-medium">View Bookings</span>
            </a>
            <a href="/settings" className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left block">
              <span className="text-2xl mb-2 block">⚙️</span>
              <span className="text-text-primary font-medium">Settings</span>
            </a>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    minimumFractionDigits: 0,
  }).format(amount)
}
