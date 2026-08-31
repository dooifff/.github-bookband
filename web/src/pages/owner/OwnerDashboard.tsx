import { useState, useEffect, useCallback } from 'react'
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

  const fetchDashboard = useCallback(async () => {
    try {
      const response = await api.get('/owner/dashboard')
      setStats(response.data.data)
    } catch (error) {
      console.error('Failed to fetch dashboard:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchDashboard() }, [fetchDashboard])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const statCards = [
    { title: 'Studio Saya', value: stats?.total_studios || 0, icon: '🏠', iconBg: 'bg-blue-500/10' },
    { title: 'Total Pemesanan', value: stats?.total_bookings || 0, icon: '📅', iconBg: 'bg-purple-500/10' },
    { title: 'Menunggu', value: stats?.pending_bookings || 0, icon: '⏳', iconBg: 'bg-warning/10' },
    { title: 'Total Pendapatan', value: formatCurrency(stats?.total_revenue || 0), icon: '💰', iconBg: 'bg-success/10' },
  ]

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

  return (
    <AdminLayout>
      <div className="space-y-8">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Dasbor Pemilik</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola studio Anda dan pantau performa</p>
        </div>

        {/* Stats */}
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
          {/* Today's Bookings */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-5">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Pemesanan Hari Ini</h2>
              <a href="/owner/bookings" className="text-accent text-xs font-medium hover:text-accent-hover transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1">
              {stats?.today_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-surface-lighter flex items-center justify-center text-sm">
                      {booking.user?.name?.charAt(0) || 'C'}
                    </div>
                    <div>
                      <p className="text-text-primary text-sm font-medium">{booking.user?.name || 'Customer'}</p>
                      <p className="text-text-muted text-xs">{booking.room?.name} • {booking.start_time} – {booking.end_time}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-0.5 text-[0.65rem] font-medium rounded-full ${
                    booking.status === 'confirmed' ? 'bg-success/10 text-success' :
                    booking.status === 'pending' ? 'bg-warning/10 text-warning' :
                    'bg-text-muted/10 text-text-muted'
                  }`}>{booking.status}</span>
                </div>
              ))}
              {(!stats?.today_bookings || stats.today_bookings.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">Tidak ada pemesanan hari ini</p>
              )}
            </div>
          </div>

          {/* Upcoming Bookings */}
          <div className="card-luxury p-6 animate-fade-in-up stagger-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-base font-semibold text-text-primary">Pemesanan Mendatang</h2>
            </div>
            <div className="space-y-1">
              {stats?.upcoming_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-surface-lighter flex items-center justify-center text-sm">
                      {booking.user?.name?.charAt(0) || 'C'}
                    </div>
                    <div>
                      <p className="text-text-primary text-sm font-medium">{booking.user?.name || 'Customer'}</p>
                      <p className="text-text-muted text-xs">{booking.studio?.name} • {booking.booking_date}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-block px-2 py-0.5 text-[0.65rem] font-medium rounded-full ${
                      booking.status === 'confirmed' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'
                    }`}>{booking.status}</span>
                    <p className="text-text-muted text-xs mt-0.5">{formatCurrency(booking.total_amount)}</p>
                  </div>
                </div>
              ))}
              {(!stats?.upcoming_bookings || stats.upcoming_bookings.length === 0) && (
                <p className="text-text-muted text-center py-8 text-sm">Tidak ada pemesanan mendatang</p>
              )}
            </div>
          </div>
        </div>

        {/* Recent Reviews */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-7">
          <h2 className="text-base font-semibold text-text-primary mb-5">Ulasan Terbaru</h2>
          <div className="space-y-1">
            {stats?.recent_reviews?.slice(0, 3).map((review) => (
              <div key={review.id} className="py-4 px-4 -mx-4 rounded-xl hover:bg-surface-lighter/30 transition-colors">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-7 h-7 rounded-lg bg-accent/10 flex items-center justify-center text-xs">
                      {review.user?.name?.charAt(0) || 'U'}
                    </div>
                    <p className="text-text-primary text-sm font-medium">{review.user?.name || 'User'}</p>
                  </div>
                  <div className="flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <span key={i} className={`text-xs ${i < review.rating ? 'text-warning' : 'text-text-muted/30'}`}>★</span>
                    ))}
                    <span className="text-text-muted text-xs ml-1">{review.rating}</span>
                  </div>
                </div>
                <p className="text-text-secondary text-sm leading-relaxed">{review.comment}</p>
                <p className="text-text-muted text-xs mt-1.5">{review.studio?.name}</p>
              </div>
            ))}
            {(!stats?.recent_reviews || stats.recent_reviews.length === 0) && (
              <p className="text-text-muted text-center py-8 text-sm">Belum ada ulasan</p>
            )}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
