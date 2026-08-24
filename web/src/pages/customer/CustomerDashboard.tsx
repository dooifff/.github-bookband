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

  useEffect(() => { fetchDashboard() }, [])

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
        upcoming_bookings: bookings.filter((b: any) => ['pending', 'confirmed', 'awaiting_payment'].includes(b.status)).slice(0, 5),
        notifications: notifs.slice(0, 3),
      })
    } catch (error) {
      console.error('Failed to fetch dashboard:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Loading dashboard...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  const statCards = [
    { title: 'My Bookings', value: data?.total_bookings || 0, icon: '📅', iconBg: 'bg-blue-500/10' },
    { title: 'Pending', value: data?.pending_bookings || 0, icon: '⏳', iconBg: 'bg-warning/10' },
    { title: 'Completed', value: data?.completed_bookings || 0, icon: '✅', iconBg: 'bg-success/10' },
    { title: 'Favorites', value: data?.total_favorites || 0, icon: '❤️', iconBg: 'bg-red-500/10' },
  ]

  return (
    <AdminLayout>
      <div className="space-y-8">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">My Dashboard</h1>
          <p className="text-text-secondary mt-1 text-sm">Welcome back! Manage your bookings and studios.</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-5">
          {statCards.map((stat, i) => (
            <div key={stat.title} className={`card-luxury p-5 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-center justify-between">
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

        {/* Quick Actions */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { href: '/customer/studios', icon: '🔍', label: 'Find Studios' },
            { href: '/customer/bookings', icon: '📅', label: 'My Bookings' },
            { href: '/customer/favorites', icon: '❤️', label: 'Favorites' },
            { href: '/customer/notifications', icon: '🔔', label: 'Notifications' },
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

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Upcoming Bookings */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-5">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Upcoming Bookings</h2>
              <a href="/customer/bookings" className="text-accent text-xs font-medium hover:text-accent-hover transition-colors">View all →</a>
            </div>
            <div className="space-y-1">
              {data?.upcoming_bookings?.map((booking: any) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                  <div>
                    <p className="text-text-primary text-sm font-medium">{booking.studio?.name || 'Studio'}</p>
                    <p className="text-text-muted text-xs">{booking.room?.name} • {booking.date}</p>
                  </div>
                  <div className="text-right">
                    <span className={`inline-block px-2 py-0.5 text-[0.65rem] font-medium rounded-full ${
                      booking.status === 'confirmed' ? 'bg-success/10 text-success' :
                      booking.status === 'pending' ? 'bg-warning/10 text-warning' :
                      'bg-accent/10 text-accent'
                    }`}>
                      {booking.status === 'confirmed' ? 'Confirmed' : booking.status === 'pending' ? 'Pending' : 'Awaiting Payment'}
                    </span>
                    <p className="text-text-muted text-xs mt-0.5">{formatCurrency(booking.total)}</p>
                  </div>
                </div>
              ))}
              {(!data?.upcoming_bookings || data.upcoming_bookings.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">No upcoming bookings</p>
              )}
            </div>
          </div>

          {/* Notifications */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Notifications</h2>
              <a href="/customer/notifications" className="text-accent text-xs font-medium hover:text-accent-hover transition-colors">View all →</a>
            </div>
            <div className="space-y-1">
              {data?.notifications?.map((notif: any) => (
                <div key={notif.id} className={`flex items-start gap-3 py-3 px-3 -mx-3 rounded-xl transition-colors ${!notif.is_read ? 'bg-accent/[0.03]' : 'hover:bg-surface-lighter/30'}`}>
                  <div className="w-8 h-8 rounded-lg bg-surface-lighter flex items-center justify-center text-sm flex-shrink-0 mt-0.5">
                    {notif.type === 'booking' ? '📅' : notif.type === 'payment' ? '💳' : '🔔'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-text-primary text-sm font-medium">{notif.title}</p>
                      {!notif.is_read && <span className="w-1.5 h-1.5 rounded-full bg-accent flex-shrink-0" />}
                    </div>
                    <p className="text-text-muted text-xs mt-0.5">{notif.body}</p>
                  </div>
                </div>
              ))}
              {(!data?.notifications || data.notifications.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">No notifications</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
