import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'
import { censorText } from '../../utils/profanityFilter'

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
    { title: 'STUDIO SAYA', value: stats?.total_studios || 0, icon: '🏠', iconBg: 'bg-blue-500/10' },
    { title: 'TOTAL BOOKING', value: stats?.total_bookings || 0, icon: '📅', iconBg: 'bg-purple-500/10' },
    { title: 'MENUNGGU', value: stats?.pending_bookings || 0, icon: '⏳', iconBg: 'bg-[#f6ad55]/10' },
    { title: 'PENDAPATAN', value: formatCurrency(stats?.total_revenue || 0), icon: '💰', iconBg: 'bg-[#48bb78]/10' },
  ]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-[#e53e3e]/30 border-t-[#e53e3e] rounded-full animate-spin" />
            <p className="text-gray-500 text-sm">Loading dashboard...</p>
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
          <h1 className="text-3xl font-black tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
            OWNER DASHBOARD
          </h1>
          <p className="text-gray-500 mt-1 text-sm tracking-wide">Kelola studio Anda dan pantau performa</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {statCards.map((stat, i) => (
            <div key={stat.title} className={`bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-500 text-xs font-semibold tracking-widest uppercase">{stat.title}</p>
                  <p className="text-2xl font-black text-white mt-2 tracking-tight">{stat.value}</p>
                </div>
                <div className={`w-11 h-11 rounded ${stat.iconBg} flex items-center justify-center text-lg`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Content Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Today's Bookings */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-5">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-sm font-bold text-white tracking-wide">PEMESANAN HARI INI</h2>
              <a href="/owner/bookings" className="text-[#e53e3e] text-xs font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1">
              {stats?.today_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded hover:bg-[#111] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded bg-[#1a1a1a] flex items-center justify-center text-sm">
                      {booking.user?.name?.charAt(0) || 'C'}
                    </div>
                    <div>
                      <p className="text-white text-sm font-medium">{booking.user?.name || 'Customer'}</p>
                      <p className="text-gray-500 text-xs">{booking.room?.name} • {booking.start_time} – {booking.end_time}</p>
                    </div>
                  </div>
                  <span className={`px-2 py-0.5 text-[0.65rem] font-semibold rounded ${
                    booking.status === 'confirmed' ? 'bg-[#48bb78]/10 text-[#48bb78]' :
                    booking.status === 'pending' ? 'bg-[#f6ad55]/10 text-[#f6ad55]' :
                    'bg-white/5 text-gray-400'
                  }`}>{booking.status}</span>
                </div>
              ))}
              {(!stats?.today_bookings || stats.today_bookings.length === 0) && (
                <p className="text-gray-500 text-center py-8 text-sm">Tidak ada pemesanan hari ini</p>
              )}
            </div>
          </div>

          {/* Upcoming Bookings */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-6">
            <div className="flex items-center justify-between mb-5">
              <h2 className="text-sm font-bold text-white tracking-wide">PEMESANAN MENDATANG</h2>
            </div>
            <div className="space-y-1">
              {stats?.upcoming_bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded hover:bg-[#111] transition-colors">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded bg-[#1a1a1a] flex items-center justify-center text-sm">
                      {booking.user?.name?.charAt(0) || 'C'}
                    </div>
                    <div>
                      <p className="text-white text-sm font-medium">{booking.user?.name || 'Customer'}</p>
                      <p className="text-gray-500 text-xs">{booking.studio?.name} • {booking.booking_date}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-block px-2 py-0.5 text-[0.65rem] font-semibold rounded ${
                      booking.status === 'confirmed' ? 'bg-[#48bb78]/10 text-[#48bb78]' : 'bg-[#f6ad55]/10 text-[#f6ad55]'
                    }`}>{booking.status}</span>
                    <p className="text-gray-500 text-xs mt-0.5">{formatCurrency(booking.total_amount)}</p>
                  </div>
                </div>
              ))}
              {(!stats?.upcoming_bookings || stats.upcoming_bookings.length === 0) && (
                <p className="text-gray-500 text-center py-8 text-sm">Tidak ada pemesanan mendatang</p>
              )}
            </div>
          </div>
        </div>

        {/* Recent Reviews */}
        <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-7">
          <h2 className="text-sm font-bold text-white mb-5 tracking-wide">ULASAN TERBARU</h2>
          <div className="space-y-1">
            {stats?.recent_reviews?.slice(0, 3).map((review) => (
              <div key={review.id} className="py-4 px-4 -mx-4 rounded hover:bg-[#111] transition-colors">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <div className="w-7 h-7 rounded bg-[#e53e3e]/10 flex items-center justify-center text-xs">
                      {review.user?.name?.charAt(0) || 'U'}
                    </div>
                    <p className="text-white text-sm font-medium">{review.user?.name || 'User'}</p>
                  </div>
                  <div className="flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <span key={i} className={`text-xs ${i < review.rating ? 'text-[#f6ad55]' : 'text-white/10'}`}>★</span>
                    ))}
                    <span className="text-gray-500 text-xs ml-1">{review.rating}</span>
                  </div>
                </div>
                <p className="text-gray-400 text-sm leading-relaxed">{censorText(review.comment || '')}</p>
                <p className="text-gray-500 text-xs mt-1.5">{review.studio?.name}</p>
              </div>
            ))}
            {(!stats?.recent_reviews || stats.recent_reviews.length === 0) && (
              <p className="text-gray-500 text-center py-8 text-sm">Belum ada ulasan</p>
            )}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
