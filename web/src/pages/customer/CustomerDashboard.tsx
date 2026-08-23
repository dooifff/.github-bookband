import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface CustomerData {
  total_bookings: number
  pending_bookings: number
  completed_bookings: number
  total_favorites: number
  upcoming_bookings: any[]
  notifications: any[]
}

export default function CustomerDashboard() {
  const [data, setData] = useState<CustomerData | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchDashboard()
  }, [])

  const fetchDashboard = async () => {
    try {
      const [bookingsRes, favRes, notifRes] = await Promise.all([
        api.get('/bookings?per_page=5'),
        api.get('/favorites'),
        api.get('/notifications?per_page=3'),
      ])

      const bookings = bookingsRes.data.data || []
      const favs = favRes.data.data || []
      const notifs = notifRes.data.data || []

      setData({
        total_bookings: bookings.length,
        pending_bookings: bookings.filter((b: any) => b.status === 'pending').length,
        completed_bookings: bookings.filter((b: any) => b.status === 'completed').length,
        total_favorites: favs.length,
        upcoming_bookings: bookings.filter((b: any) =>
          ['pending', 'confirmed', 'awaiting_payment'].includes(b.status)
        ).slice(0, 5),
        notifications: notifs.slice(0, 3),
      })
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

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading dashboard...</div>
        </div>
      </AdminLayout>
    )
  }

  const statCards = [
    { title: 'My Bookings', value: data?.total_bookings || 0, icon: '📅', color: 'bg-blue-500/10 text-blue-500' },
    { title: 'Pending', value: data?.pending_bookings || 0, icon: '⏳', color: 'bg-amber-500/10 text-amber-500' },
    { title: 'Completed', value: data?.completed_bookings || 0, icon: '✅', color: 'bg-green-500/10 text-green-500' },
    { title: 'Favorites', value: data?.total_favorites || 0, icon: '❤️', color: 'bg-red-500/10 text-red-500' },
  ]

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-text-primary">My Dashboard</h1>
          <p className="text-text-secondary">Welcome back! Manage your bookings and studios.</p>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {statCards.map((stat) => (
            <div key={stat.title} className="bg-surface border border-border rounded-xl p-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-text-muted text-sm">{stat.title}</p>
                  <p className="text-2xl font-bold text-text-primary mt-1">{stat.value}</p>
                </div>
                <div className={`w-11 h-11 rounded-lg flex items-center justify-center text-xl ${stat.color}`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <a href="/customer/studios" className="p-4 bg-surface border border-border rounded-xl hover:border-accent transition-colors text-center">
            <span className="text-2xl mb-2 block">🔍</span>
            <span className="text-text-primary font-medium text-sm">Find Studios</span>
          </a>
          <a href="/customer/bookings" className="p-4 bg-surface border border-border rounded-xl hover:border-accent transition-colors text-center">
            <span className="text-2xl mb-2 block">📅</span>
            <span className="text-text-primary font-medium text-sm">My Bookings</span>
          </a>
          <a href="/customer/favorites" className="p-4 bg-surface border border-border rounded-xl hover:border-accent transition-colors text-center">
            <span className="text-2xl mb-2 block">❤️</span>
            <span className="text-text-primary font-medium text-sm">Favorites</span>
          </a>
          <a href="/customer/notifications" className="p-4 bg-surface border border-border rounded-xl hover:border-accent transition-colors text-center">
            <span className="text-2xl mb-2 block">🔔</span>
            <span className="text-text-primary font-medium text-sm">Notifications</span>
          </a>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Upcoming Bookings */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-text-primary">Upcoming Bookings</h2>
              <a href="/customer/bookings" className="text-accent text-sm hover:underline">View all</a>
            </div>
            <div className="space-y-3">
              {data?.upcoming_bookings?.map((booking: any) => (
                <div key={booking.id} className="flex items-center justify-between py-2 border-b border-border last:border-0">
                  <div>
                    <p className="text-text-primary font-medium">{booking.studio?.name || 'Studio'}</p>
                    <p className="text-text-muted text-sm">{booking.room?.name} • {booking.date}</p>
                  </div>
                  <div className="text-right">
                    <span className={`px-2 py-1 text-xs rounded ${
                      booking.status === 'confirmed' ? 'bg-success/20 text-success' :
                      booking.status === 'pending' ? 'bg-warning/20 text-warning' :
                      'bg-accent/20 text-accent'
                    }`}>
                      {booking.status === 'confirmed' ? 'Confirmed' :
                       booking.status === 'pending' ? 'Pending' :
                       booking.status === 'awaiting_payment' ? 'Awaiting Payment' :
                       booking.status}
                    </span>
                    <p className="text-text-muted text-sm mt-1">{formatCurrency(booking.total)}</p>
                  </div>
                </div>
              ))}
              {(!data?.upcoming_bookings || data.upcoming_bookings.length === 0) && (
                <p className="text-text-muted text-center py-4">No upcoming bookings</p>
              )}
            </div>
          </div>

          {/* Notifications */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-lg font-semibold text-text-primary">Notifications</h2>
              <a href="/customer/notifications" className="text-accent text-sm hover:underline">View all</a>
            </div>
            <div className="space-y-3">
              {data?.notifications?.map((notif: any) => (
                <div key={notif.id} className={`flex items-start gap-3 py-2 border-b border-border last:border-0 ${!notif.is_read ? 'bg-accent/5 -mx-2 px-2 rounded' : ''}`}>
                  <div className="w-8 h-8 bg-accent/10 rounded-full flex items-center justify-center text-sm flex-shrink-0">
                    {notif.type === 'booking' ? '📅' : notif.type === 'payment' ? '💳' : '🔔'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-text-primary font-medium text-sm">{notif.title}</p>
                    <p className="text-text-muted text-xs">{notif.body}</p>
                  </div>
                </div>
              ))}
              {(!data?.notifications || data.notifications.length === 0) && (
                <p className="text-text-muted text-center py-4">No notifications</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
