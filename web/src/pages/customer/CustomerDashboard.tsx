import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Studio {
  id: number
  name: string
  slug: string
  city: string
  province: string
  address: string
  average_rating: number
  total_reviews: number
  is_verified: boolean
  images: { url: string; is_primary: boolean }[]
}

interface FavoriteStudio {
  id: number
  studio: Studio
}

interface CustomerData {
  total_bookings: number
  pending_bookings: number
  completed_bookings: number
  total_favorites: number
  upcoming_bookings: any[]
  notifications: any[]
  studios: Studio[]
  favorite_studios: FavoriteStudio[]
}

function getItems(res: any): any[] {
  return res?.data?.items || res?.data?.data || []
}

export default function CustomerDashboard() {
  const [data, setData] = useState<CustomerData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [studioSearch, setStudioSearch] = useState('')
  const [studioCity, setStudioCity] = useState('')
  const [searchResults, setSearchResults] = useState<Studio[] | null>(null)
  const [searching, setSearching] = useState(false)

  const fetchDashboard = useCallback(async () => {
    try {
      const [bookingsRes, favRes, notifRes, studiosRes] = await Promise.allSettled([
        api.get('/bookings?per_page=5'),
        api.get('/favorites'),
        api.get('/notifications?per_page=3'),
        api.get('/studios?per_page=6'),
      ])
      const bookings = bookingsRes.status === 'fulfilled' ? getItems(bookingsRes.value) : []
      const favs = favRes.status === 'fulfilled' ? getItems(favRes.value) : []
      const notifs = notifRes.status === 'fulfilled' ? getItems(notifRes.value) : []
      const studios = studiosRes.status === 'fulfilled' ? getItems(studiosRes.value) : []
      setData({
        total_bookings: bookings.length,
        pending_bookings: bookings.filter((b: any) => b.status === 'pending').length,
        completed_bookings: bookings.filter((b: any) => b.status === 'completed').length,
        total_favorites: favs.length,
        upcoming_bookings: bookings.filter((b: any) => ['pending', 'confirmed', 'awaiting_payment'].includes(b.status)).slice(0, 5),
        notifications: notifs.slice(0, 3),
        studios: studios,
        favorite_studios: favs.slice(0, 4),
      })
    } catch (error: any) {
      console.error('Failed to fetch dashboard:', error)
      setError(error?.response?.data?.message || error?.message || 'Gagal memuat data')
    } finally {
      setLoading(false)
    }
  }, [])

  const searchStudios = useCallback(async () => {
    if (!studioSearch && !studioCity) {
      setSearchResults(null)
      return
    }
    setSearching(true)
    try {
      const params = new URLSearchParams()
      if (studioSearch) params.set('search', studioSearch)
      if (studioCity) params.set('city', studioCity)
      const res = await api.get(`/studios?${params.toString()}&per_page=12`)
      setSearchResults(getItems(res))
    } catch (error) {
      console.error('Failed to search studios:', error)
    } finally {
      setSearching(false)
    }
  }, [studioSearch, studioCity])

  useEffect(() => { fetchDashboard() }, [fetchDashboard])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-[#e53e3e]/20 border-t-[#e53e3e] rounded-full animate-spin" />
            <p className="text-gray-500 text-sm tracking-wide">Memuat dasbor...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center bg-[#0d0d0d] border border-white/5 rounded p-8">
            <p className="text-[#e53e3e] mb-4">{error}</p>
            <button onClick={fetchDashboard} className="btn-red text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  const statCards = [
    { title: 'PEMESANAN', value: data?.total_bookings || 0, icon: '📅', color: 'rgba(59,130,246,0.12)', accent: 'text-blue-400', border: 'border-l-blue-500/40' },
    { title: 'MENUNGGU', value: data?.pending_bookings || 0, icon: '⏳', color: 'rgba(234,179,8,0.12)', accent: 'text-[#f6ad55]', border: 'border-l-yellow-500/40' },
    { title: 'SELESAI', value: data?.completed_bookings || 0, icon: '✅', color: 'rgba(34,197,94,0.12)', accent: 'text-[#48bb78]', border: 'border-l-green-500/40' },
    { title: 'FAVORIT', value: data?.total_favorites || 0, icon: '❤️', color: 'rgba(239,68,68,0.12)', accent: 'text-[#e53e3e]', border: 'border-l-[#e53e3e]/40' },
  ]

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-black tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
            MY DASHBOARD
          </h1>
          <p className="text-gray-500 mt-1.5 text-sm tracking-wide">Selamat datang kembali! Kelola pemesanan dan studio Anda.</p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {statCards.map((stat, i) => (
            <div
              key={stat.title}
              className={`bg-[#0d0d0d] border border-white/5 border-l-2 ${stat.border} rounded p-4 animate-fade-in-up stagger-${i + 1}`}
            >
              <div className="flex items-center justify-between">
                <div className="flex flex-col justify-center">
                  <p className="text-gray-500 text-[0.65rem] font-semibold tracking-widest uppercase">{stat.title}</p>
                  <p className={`text-2xl font-black mt-1.5 tracking-tight ${stat.accent}`}>{stat.value}</p>
                </div>
                <div
                  className="w-11 h-11 rounded flex items-center justify-center text-xl"
                  style={{ background: stat.color, border: `1px solid ${stat.color}` }}
                >
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Quick Actions */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { href: '/customer/studios', icon: '🔍', label: 'Cari Studio', desc: 'Temukan studio' },
            { href: '/customer/bookings', icon: '📅', label: 'Pemesanan', desc: 'Kelola booking' },
            { href: '/customer/favorites', icon: '❤️', label: 'Favorit', desc: 'Studio favorit' },
            { href: '/customer/notifications', icon: '🔔', label: 'Notifikasi', desc: 'Update terbaru' },
          ].map((action) => (
            <a
              key={action.href}
              href={action.href}
              className="group flex flex-col items-center gap-3 p-5 text-center bg-[#0d0d0d] border border-white/5 rounded hover:border-[#e53e3e]/20 hover:bg-[#111] transition-all duration-300"
            >
              <div className="w-16 h-16 rounded bg-gradient-to-br from-[#e53e3e]/15 to-[#e53e3e]/5 border border-[#e53e3e]/10 flex items-center justify-center text-2xl group-hover:scale-110 transition-all duration-300">
                {action.icon}
              </div>
              <div>
                <span className="text-white text-sm font-semibold block group-hover:text-[#e53e3e] transition-colors">{action.label}</span>
                <span className="text-gray-500 text-xs mt-0.5 block">{action.desc}</span>
              </div>
            </a>
          ))}
        </div>

        {/* Studio Search */}
        <div className="bg-[#0d0d0d] border border-white/5 rounded p-6 animate-fade-in-up stagger-3">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-sm font-bold flex items-center gap-2.5">
              <span className="w-8 h-8 rounded bg-[#e53e3e]/10 border border-[#e53e3e]/15 flex items-center justify-center text-sm">🔍</span>
              <span className="text-white tracking-wide">CARI STUDIO</span>
            </h2>
            <a href="/customer/studios" className="text-[#e53e3e] text-xs font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</a>
          </div>
          <div className="flex gap-3 mb-5">
            <input
              type="text"
              value={studioSearch}
              onChange={(e) => setStudioSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && searchStudios()}
              placeholder="Cari nama studio..."
              className="flex-1 px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
            />
            <input
              type="text"
              value={studioCity}
              onChange={(e) => setStudioCity(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && searchStudios()}
              placeholder="Kota..."
              className="w-40 px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
            />
            <button onClick={searchStudios} className="btn-red text-sm py-2.5 px-6">
              {searching ? (
                <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
              ) : '🔍 Cari'}
            </button>
          </div>

          {searching ? (
            <div className="flex items-center justify-center py-12">
              <div className="flex flex-col items-center gap-3">
                <div className="w-8 h-8 border-2 border-[#e53e3e]/20 border-t-[#e53e3e] rounded-full animate-spin" />
                <p className="text-gray-500 text-xs">Mencari studio...</p>
              </div>
            </div>
          ) : (searchResults !== null ? searchResults : data?.studios || []).length === 0 ? (
            <div className="text-center py-12">
              <span className="text-4xl block mb-3 opacity-40">🎵</span>
              <p className="text-gray-500 text-sm">
                {searchResults !== null ? 'Tidak ada studio ditemukan' : 'Belum ada studio tersedia'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
              {(searchResults !== null ? searchResults : data?.studios || []).map((studio: Studio, i: number) => (
                <a
                  key={studio.id}
                  href={`/customer/studios/${studio.slug}`}
                  className={`bg-[#0d0d0d] border border-white/5 rounded overflow-hidden hover:border-[#e53e3e]/20 transition-all duration-300 group animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}
                >
                  <div className="h-44 relative overflow-hidden">
                    <div className="w-full h-full bg-gradient-to-br from-[#e53e3e]/15 via-[#e53e3e]/5 to-[#0d0d0d] flex items-center justify-center">
                      <span className="text-5xl opacity-50 group-hover:opacity-70 transition-opacity">🎵</span>
                    </div>
                    {studio.is_verified && (
                      <div className="absolute top-3 left-3 px-2.5 py-1 bg-[#e53e3e]/20 backdrop-blur-md border border-[#e53e3e]/25 rounded text-[#e53e3e] text-[0.6rem] font-semibold flex items-center gap-1">
                        <span className="w-1.5 h-1.5 rounded-full bg-[#e53e3e] animate-pulse" />
                        Terverifikasi
                      </div>
                    )}
                    <div className="absolute inset-0 bg-gradient-to-t from-[#0d0d0d]/80 via-transparent to-transparent" />
                  </div>
                  <div className="p-4">
                    <h3 className="text-white font-bold text-sm mb-1.5 group-hover:text-[#e53e3e] transition-colors">{studio.name}</h3>
                    <p className="text-gray-500 text-xs mb-3 flex items-center gap-1">📍 {studio.city}{studio.province ? `, ${studio.province}` : ''}</p>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-1.5">
                        <span className="text-[#f6ad55] text-xs">★</span>
                        <span className="text-white text-sm font-bold">{studio.average_rating}</span>
                        <span className="text-gray-500 text-xs">({studio.total_reviews})</span>
                      </div>
                      <span className="btn-red text-[0.65rem] py-1.5 px-4 font-semibold">
                        Lihat & Book
                      </span>
                    </div>
                  </div>
                </a>
              ))}
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Upcoming Bookings */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-5">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-bold text-white flex items-center gap-2.5 tracking-wide">
                <span className="w-8 h-8 rounded bg-blue-500/10 border border-blue-500/15 flex items-center justify-center text-sm">📅</span>
                PEMESANAN MENDATANG
              </h2>
              <a href="/customer/bookings" className="text-[#e53e3e] text-xs font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1.5">
              {data?.upcoming_bookings?.map((booking: any) => (
                <div key={booking.id} className="flex items-center justify-between py-2.5 px-3 -mx-3 rounded hover:bg-[#111] transition-all duration-300 group">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded bg-gradient-to-br from-[#e53e3e]/10 to-[#e53e3e]/5 border border-[#e53e3e]/10 flex items-center justify-center text-sm flex-shrink-0">
                      🎵
                    </div>
                    <div>
                      <p className="text-white text-sm font-semibold group-hover:text-[#e53e3e] transition-colors">{booking.studio?.name || 'Studio'}</p>
                      <p className="text-gray-500 text-xs">{booking.room?.name} • {booking.date}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`inline-block px-2.5 py-1 text-[0.65rem] font-semibold rounded ${
                      booking.status === 'confirmed' ? 'bg-[#48bb78]/10 text-[#48bb78] border border-[#48bb78]/15' :
                      booking.status === 'pending' ? 'bg-[#f6ad55]/10 text-[#f6ad55] border border-[#f6ad55]/15' :
                      'bg-[#e53e3e]/10 text-[#e53e3e] border border-[#e53e3e]/15'
                    }`}>
                      {booking.status === 'confirmed' ? 'Dikonfirmasi' : booking.status === 'pending' ? 'Menunggu' : 'Bayar'}
                    </span>
                    <p className="text-gray-500 text-xs mt-1 font-medium">{formatCurrency(booking.total)}</p>
                  </div>
                </div>
              ))}
              {(!data?.upcoming_bookings || data.upcoming_bookings.length === 0) && (
                <div className="text-center py-10">
                  <span className="text-3xl block mb-2 opacity-30">📅</span>
                  <p className="text-gray-500 text-sm">Tidak ada pemesanan mendatang</p>
                </div>
              )}
            </div>
          </div>

          {/* Notifications */}
          <div className="bg-[#0d0d0d] border border-white/5 rounded p-5 animate-fade-in-up stagger-6">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-bold text-white flex items-center gap-2.5 tracking-wide">
                <span className="w-8 h-8 rounded bg-[#e53e3e]/10 border border-[#e53e3e]/15 flex items-center justify-center text-sm">🔔</span>
                NOTIFIKASI
              </h2>
              <a href="/customer/notifications" className="text-[#e53e3e] text-xs font-semibold hover:text-[#fc8181] transition-colors">Lihat semua →</a>
            </div>
            <div className="space-y-1.5">
              {data?.notifications?.map((notif: any) => (
                <div key={notif.id} className={`flex items-start gap-3.5 py-2.5 px-3 -mx-3 rounded transition-all duration-300 ${!notif.is_read ? 'bg-[#e53e3e]/[0.04] border-l-2 border-l-[#e53e3e]/30' : 'hover:bg-[#111]'}`}>
                  <div className="w-9 h-9 rounded bg-gradient-to-br from-[#1a1a1a] to-[#0d0d0d] flex items-center justify-center text-sm flex-shrink-0 mt-0.5 border border-white/5">
                    {notif.type === 'booking' ? '📅' : notif.type === 'payment' ? '💳' : '🔔'}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <p className="text-white text-sm font-semibold">{notif.title}</p>
                      {!notif.is_read && <span className="w-2 h-2 rounded-full bg-[#e53e3e] flex-shrink-0 animate-pulse" />}
                    </div>
                    <p className="text-gray-500 text-xs mt-0.5 leading-relaxed">{notif.body}</p>
                  </div>
                </div>
              ))}
              {(!data?.notifications || data.notifications.length === 0) && (
                <div className="text-center py-10">
                  <span className="text-3xl block mb-2 opacity-30">🔔</span>
                  <p className="text-gray-500 text-sm">Tidak ada notifikasi</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
