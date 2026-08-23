import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface DashboardStats {
  total_studios: number
  active_studios: number
  total_bookings: number
  pending_bookings: number
  completed_bookings: number
  total_revenue: number
  average_rating: number
  today_bookings: any[]
  upcoming_bookings: any[]
  recent_reviews: any[]
}

export default function OwnerDashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboard()
  }, [])

  const fetchDashboard = async () => {
    try {
      const response = await api.get('/owner/dashboard')
      setStats(response.data.data)
    } catch (error) {
      console.error('Failed to fetch dashboard:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount)
  }

  const statCards = [
    { title: 'My Studios', value: stats?.total_studios || 0, icon: '🏠', color: 'bg-blue-500/10 text-blue-500' },
    { title: 'Total Bookings', value: stats?.total_bookings || 0, icon: '📅', color: 'bg-purple-500/10 text-purple-500' },
    { title: 'Pending', value: stats?.pending_bookings || 0, icon: '⏳', color: 'bg-amber-500/10 text-amber-500' },
    { title: 'Total Revenue', value: formatCurrency(stats?.total_revenue || 0), icon: '💰', color: 'bg-green-500/10 text-green-500' },
  ]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent">Loading dashboard...</div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Owner Dashboard</h1>
          <p className="text-text-secondary">Manage your studios and bookings</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {statCards.map((stat) => (
            <div key={stat.title} className="bg-surface border border-border rounded-xl p-6">
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

        {/* Today's Bookings */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Today's Bookings</h2>
          <div className="space-y-3">
            {stats?.today_bookings?.slice(0, 5).map((booking) => (
              <div key={booking.id} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                <div>
                  <p className="text-text-primary font-medium">{booking.user?.name || 'Customer'}</p>
                  <p className="text-text-muted text-sm">{booking.room?.name} • {booking.start_time} - {booking.end_time}</p>
                </div>
                <span className={`px-2 py-1 text-xs rounded ${
                  booking.status === 'confirmed' ? 'bg-success/20 text-success' :
                  booking.status === 'pending' ? 'bg-warning/20 text-warning' :
                  'bg-text-muted/20 text-text-muted'
                }`}>
                  {booking.status}
                </span>
              </div>
            ))}
            {(!stats?.today_bookings || stats.today_bookings.length === 0) && (
              <p className="text-text-muted text-center py-4">No bookings today</p>
            )}
          </div>
        </div>

        {/* Upcoming Bookings */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Upcoming Bookings</h2>
          <div className="space-y-3">
            {stats?.upcoming_bookings?.slice(0, 5).map((booking) => (
              <div key={booking.id} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                <div>
                  <p className="text-text-primary font-medium">{booking.user?.name || 'Customer'}</p>
                  <p className="text-text-muted text-sm">{booking.studio?.name} • {booking.booking_date}</p>
                </div>
                <div className="text-right">
                  <span className={`px-2 py-1 text-xs rounded ${
                    booking.status === 'confirmed' ? 'bg-success/20 text-success' :
                    'bg-warning/20 text-warning'
                  }`}>
                    {booking.status}
                  </span>
                  <p className="text-text-muted text-sm mt-1">{formatCurrency(booking.total_amount)}</p>
                </div>
              </div>
            ))}
            {(!stats?.upcoming_bookings || stats.upcoming_bookings.length === 0) && (
              <p className="text-text-muted text-center py-4">No upcoming bookings</p>
            )}
          </div>
        </div>

        {/* Recent Reviews */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Recent Reviews</h2>
          <div className="space-y-3">
            {stats?.recent_reviews?.slice(0, 3).map((review) => (
              <div key={review.id} className="py-3 border-b border-border last:border-0">
                <div className="flex items-center justify-between mb-2">
                  <p className="text-text-primary font-medium">{review.user?.name || 'User'}</p>
                  <div className="flex items-center gap-1">
                    <span className="text-warning">⭐</span>
                    <span className="text-text-primary">{review.rating}</span>
                  </div>
                </div>
                <p className="text-text-secondary text-sm">{review.comment}</p>
                <p className="text-text-muted text-xs mt-1">{review.studio?.name}</p>
              </div>
            ))}
            {(!stats?.recent_reviews || stats.recent_reviews.length === 0) && (
              <p className="text-text-muted text-center py-4">No reviews yet</p>
            )}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
