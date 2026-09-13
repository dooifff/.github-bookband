import { useState, useEffect, useCallback } from 'react'
import { Link } from 'react-router-dom'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface DashboardData {
  summary: {
    total_users: number
    new_users: number
    total_studios: number
    total_bookings: number
    total_revenue: number | string
    total_reviews: number
  }
  users: {
    customers: number
    owners: number
    admins: number
  }
  studios: {
    active: number | string
    inactive: number | string
    pending_verification: number | string
  }
  bookings: {
    pending: number
    completed: number
    cancelled: number
  }
  payments: {
    pending: number
    failed: number
  }
  reviews: {
    total: number
    average_rating: number
  }
  recent_activities: {
    users: { id: number; name: string; email: string; role: string; created_at: string }[]
    bookings: { id: number; booking_code: string; user: string; studio: string; amount: number | string; status: string; created_at: string }[]
    studios: { id: number; name: string; owner: string; is_verified: boolean; created_at: string }[]
  }
  period: {
    start_date: string
    end_date: string
    days: number
  }
}

export default function Dashboard() {
  const [data, setData] = useState<DashboardData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [period, setPeriod] = useState('30')

  const fetchDashboard = useCallback(async () => {
    try {
      setLoading(true)
      setError('')
      const response = await api.get(`/admin/dashboard?period=${period}`)
      setData(response.data.data)
    } catch (err: any) {
      console.error('Failed to fetch dashboard:', err)
      setError(err.response?.data?.message || 'Gagal memuat dasbor')
    } finally {
      setLoading(false)
    }
  }, [period])

  useEffect(() => { fetchDashboard() }, [fetchDashboard])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-[#f6ad55]/10 text-[#f6ad55]',
      awaiting_payment: 'bg-orange-500/10 text-orange-400',
      confirmed: 'bg-[#48bb78]/10 text-[#48bb78]',
      paid: 'bg-blue-500/10 text-blue-400',
      completed: 'bg-green-500/10 text-green-400',
      cancelled: 'bg-[#e53e3e]/10 text-[#e53e3e]',
    }
    return styles[status] || 'bg-white/5 text-gray-400'
  }

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-[#e53e3e]/30 border-t-[#e53e3e] rounded-full animate-spin" />
            <p className="text-gray-500 text-sm">Memuat dasbor...</p>
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
            <p className="text-[#e53e3e] mb-4">{error}</p>
            <button onClick={fetchDashboard} className="btn-red text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (!data) return null

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-start justify-between animate-fade-in-up">
          <div>
            <h1 className="text-3xl font-black tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
              DASHBOARD
            </h1>
            <p className="text-gray-500 mt-1 text-sm tracking-wide">
              Ringkasan platform • {data.period.days} hari terakhir
            </p>
          </div>
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            className="px-4 py-2 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none"
          >
            <option value="7">7 Hari</option>
            <option value="30">30 Hari</option>
            <option value="90">90 Hari</option>
            <option value="365">1 Tahun</option>
          </select>
        </div>

        {/* ─── Summary Stats ─── */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {[
            { title: 'TOTAL USERS', value: data.summary.total_users, icon: '👥', color: 'text-blue-400', bg: 'bg-blue-500/10' },
            { title: 'TOTAL STUDIOS', value: data.summary.total_studios, icon: '🏠', color: 'text-[#48bb78]', bg: 'bg-[#48bb78]/10' },
            { title: 'TOTAL BOOKINGS', value: data.summary.total_bookings, icon: '📅', color: 'text-purple-400', bg: 'bg-purple-500/10' },
            { title: 'REVENUE', value: formatCurrency(Number(data.summary.total_revenue) || 0), icon: '💰', color: 'text-[#e53e3e]', bg: 'bg-[#e53e3e]/10' },
            { title: 'NEW USERS', value: data.summary.new_users, icon: '🆕', color: 'text-cyan-400', bg: 'bg-cyan-500/10' },
            { title: 'REVIEWS', value: data.summary.total_reviews, icon: '⭐', color: 'text-[#f6ad55]', bg: 'bg-[#f6ad55]/10' },
          ].map((stat, i) => (
            <div key={stat.title} className={`bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-500 text-[0.65rem] font-semibold tracking-widest uppercase">{stat.title}</p>
                  <p className="text-xl font-black text-white mt-1.5 tracking-tight">{stat.value}</p>
                </div>
                <div className={`w-9 h-9 rounded ${stat.bg} flex items-center justify-center text-sm`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* ─── Breakdowns Row ─── */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Users Breakdown */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-7">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">PENGGUNA</h3>
              <Link to="/users" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-3">
              {[
                { label: 'Pelanggan', count: data.users.customers, color: 'bg-blue-400', textColor: 'text-blue-400' },
                { label: 'Pemilik Studio', count: data.users.owners, color: 'bg-[#48bb78]', textColor: 'text-[#48bb78]' },
                { label: 'Admin', count: data.users.admins, color: 'bg-[#e53e3e]', textColor: 'text-[#e53e3e]' },
              ].map((item) => {
                const total = data.summary.total_users || 1
                const pct = Math.round((item.count / total) * 100)
                return (
                  <div key={item.label}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-gray-400 text-xs">{item.label}</span>
                      <span className={`text-sm font-bold ${item.textColor}`}>{item.count}</span>
                    </div>
                    <div className="w-full h-1.5 bg-[#1a1a1a] rounded-full overflow-hidden">
                      <div className={`h-full ${item.color} rounded-full transition-all duration-500`} style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* Studios Breakdown */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-8">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">STUDIOS</h3>
              <Link to="/studios" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-3">
              {[
                { label: 'Aktif', count: Number(data.studios.active) || 0, color: 'bg-[#48bb78]', textColor: 'text-[#48bb78]' },
                { label: 'Nonaktif', count: Number(data.studios.inactive) || 0, color: 'bg-[#e53e3e]', textColor: 'text-[#e53e3e]' },
                { label: 'Menunggu Verifikasi', count: Number(data.studios.pending_verification) || 0, color: 'bg-[#f6ad55]', textColor: 'text-[#f6ad55]' },
              ].map((item) => {
                const total = data.summary.total_studios || 1
                const pct = Math.round((item.count / total) * 100)
                return (
                  <div key={item.label}>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-gray-400 text-xs">{item.label}</span>
                      <span className={`text-sm font-bold ${item.textColor}`}>{item.count}</span>
                    </div>
                    <div className="w-full h-1.5 bg-[#1a1a1a] rounded-full overflow-hidden">
                      <div className={`h-full ${item.color} rounded-full transition-all duration-500`} style={{ width: `${pct}%` }} />
                    </div>
                  </div>
                )
              })}
            </div>
          </div>

          {/* Bookings & Payments */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-9">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">BOOKING & PEMBAYARAN</h3>
              <Link to="/bookings" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-3">
              {/* Bookings */}
              <div>
                <p className="text-gray-600 text-[0.6rem] font-semibold tracking-widest uppercase mb-1">Status Booking</p>
                <div className="grid grid-cols-3 gap-2">
                  <div className="text-center p-2 bg-[#f6ad55]/5 rounded">
                    <p className="text-lg font-black text-[#f6ad55]">{data.bookings.pending}</p>
                    <p className="text-gray-500 text-[0.6rem]">Menunggu</p>
                  </div>
                  <div className="text-center p-2 bg-[#48bb78]/5 rounded">
                    <p className="text-lg font-black text-[#48bb78]">{data.bookings.completed}</p>
                    <p className="text-gray-500 text-[0.6rem]">Selesai</p>
                  </div>
                  <div className="text-center p-2 bg-[#e53e3e]/5 rounded">
                    <p className="text-lg font-black text-[#e53e3e]">{data.bookings.cancelled}</p>
                    <p className="text-gray-500 text-[0.6rem]">Batal</p>
                  </div>
                </div>
              </div>
              {/* Payments */}
              <div>
                <p className="text-gray-600 text-[0.6rem] font-semibold tracking-widest uppercase mb-1">Pembayaran</p>
                <div className="grid grid-cols-2 gap-2">
                  <div className="text-center p-2 bg-orange-500/5 rounded">
                    <p className="text-lg font-black text-orange-400">{data.payments.pending}</p>
                    <p className="text-gray-500 text-[0.6rem]">Pending</p>
                  </div>
                  <div className="text-center p-2 bg-[#e53e3e]/5 rounded">
                    <p className="text-lg font-black text-[#e53e3e]">{data.payments.failed}</p>
                    <p className="text-gray-500 text-[0.6rem]">Gagal</p>
                  </div>
                </div>
              </div>
              {/* Review Rating */}
              <div className="flex items-center justify-between p-2 bg-[#111] rounded">
                <span className="text-gray-400 text-xs">Rating Rata-rata</span>
                <div className="flex items-center gap-1">
                  <span className="text-[#f6ad55] text-sm">★</span>
                  <span className="text-white text-sm font-bold">{data.reviews.average_rating}</span>
                  <span className="text-gray-500 text-[0.6rem]">({data.reviews.total} ulasan)</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ─── Recent Activities ─── */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Recent Bookings */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-10">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">BOOKING TERBARU</h3>
              <Link to="/bookings" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-1">
              {data.recent_activities.bookings?.slice(0, 5).map((booking) => (
                <div key={booking.id} className="flex items-center justify-between py-2 px-2 -mx-2 rounded hover:bg-[#111] transition-colors">
                  <div className="flex items-center gap-2.5">
                    <div className="w-7 h-7 rounded bg-[#1a1a1a] flex items-center justify-center text-[0.65rem] font-semibold text-gray-400">
                      {booking.user?.charAt(0) || 'U'}
                    </div>
                    <div className="min-w-0">
                      <p className="text-white text-xs font-medium truncate">{booking.user}</p>
                      <p className="text-gray-500 text-[0.6rem] truncate">{booking.studio}</p>
                    </div>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <span className={`inline-block px-1.5 py-0.5 text-[0.55rem] font-semibold rounded ${getStatusBadge(booking.status)}`}>
                      {booking.status}
                    </span>
                    <p className="text-gray-500 text-[0.6rem] mt-0.5">{formatCurrency(Number(booking.amount) || 0)}</p>
                  </div>
                </div>
              ))}
              {(!data.recent_activities.bookings || data.recent_activities.bookings.length === 0) && (
                <p className="text-gray-500 text-center py-6 text-xs">Tidak ada booking terbaru</p>
              )}
            </div>
          </div>

          {/* Recent Users */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-11">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">PENGGUNA TERBARU</h3>
              <Link to="/users" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-1">
              {data.recent_activities.users?.slice(0, 5).map((user) => (
                <div key={user.id} className="flex items-center gap-2.5 py-2 px-2 -mx-2 rounded hover:bg-[#111] transition-colors">
                  <div className="w-7 h-7 rounded bg-gradient-to-br from-[#e53e3e]/15 to-[#e53e3e]/5 flex items-center justify-center border border-[#e53e3e]/10">
                    <span className="text-[#e53e3e] text-[0.65rem] font-semibold">{user.name?.charAt(0)}</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-white text-xs font-medium truncate">{user.name}</p>
                    <p className="text-gray-500 text-[0.6rem] truncate">{user.email}</p>
                  </div>
                  <span className={`px-1.5 py-0.5 text-[0.55rem] font-semibold rounded ${
                    user.role === 'super_admin' ? 'bg-[#e53e3e]/10 text-[#e53e3e]' :
                    user.role === 'admin' ? 'bg-[#e53e3e]/10 text-[#e53e3e]' :
                    user.role === 'owner' ? 'bg-[#48bb78]/10 text-[#48bb78]' :
                    'bg-blue-500/10 text-blue-400'
                  }`}>{user.role}</span>
                </div>
              ))}
              {(!data.recent_activities.users || data.recent_activities.users.length === 0) && (
                <p className="text-gray-500 text-center py-6 text-xs">Tidak ada pengguna terbaru</p>
              )}
            </div>
          </div>

          {/* Recent Studios */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-12">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-bold text-white tracking-wide">STUDIO TERBARU</h3>
              <Link to="/studios" className="text-[#e53e3e] text-[0.65rem] font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</Link>
            </div>
            <div className="space-y-1">
              {data.recent_activities.studios?.slice(0, 5).map((studio) => (
                <div key={studio.id} className="flex items-center gap-2.5 py-2 px-2 -mx-2 rounded hover:bg-[#111] transition-colors">
                  <div className="w-7 h-7 rounded bg-[#e53e3e]/10 flex items-center justify-center text-xs">🏠</div>
                  <div className="flex-1 min-w-0">
                    <p className="text-white text-xs font-medium truncate">{studio.name}</p>
                    <p className="text-gray-500 text-[0.6rem] truncate">oleh {studio.owner}</p>
                  </div>
                  {studio.is_verified && (
                    <span className="text-[#e53e3e] text-[0.6rem]">✓</span>
                  )}
                </div>
              ))}
              {(!data.recent_activities.studios || data.recent_activities.studios.length === 0) && (
                <p className="text-gray-500 text-center py-6 text-xs">Tidak ada studio terbaru</p>
              )}
            </div>
          </div>
        </div>

        {/* ─── Quick Actions ─── */}
        <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up">
          <h3 className="text-sm font-bold text-white mb-3 tracking-wide">AKSI CEPAT</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {[
              { href: '/users', icon: '👥', label: 'Kelola Pengguna', desc: `${data.summary.total_users} total` },
              { href: '/studios', icon: '🏠', label: 'Kelola Studio', desc: `${Number(data.studios.pending_verification) || 0} pending` },
              { href: '/bookings', icon: '📅', label: 'Kelola Booking', desc: `${data.bookings.pending || 0} menunggu` },
              { href: '/performance', icon: '⚡', label: 'Performa', desc: 'Monitoring server' },
            ].map((action) => (
              <Link
                key={action.href}
                to={action.href}
                className="group flex flex-col items-center gap-2 p-4 rounded bg-[#111] border border-white/5 hover:border-[#e53e3e]/20 hover:bg-[#151515] transition-all duration-300"
              >
                <span className="text-xl group-hover:scale-110 transition-transform duration-300">{action.icon}</span>
                <span className="text-gray-400 text-xs font-semibold group-hover:text-white transition-colors">{action.label}</span>
                <span className="text-gray-600 text-[0.6rem]">{action.desc}</span>
              </Link>
            ))}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
