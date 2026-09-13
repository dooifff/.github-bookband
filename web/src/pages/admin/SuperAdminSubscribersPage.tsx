import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

/* ── Types ── */

interface OwnerInfo {
  id: number
  name: string
  email: string
  phone: string | null
}

interface StudioInfo {
  id: number
  name: string
  slug: string
  city: string
  subscription_status: 'none' | 'active' | 'expired'
  subscription_expires_at: string | null
  subscription_warning_level: number
}

interface OwnerSubscription {
  id: number
  owner: OwnerInfo
  studios: StudioInfo[]
  total_studios: number
  subscription_status: 'none' | 'active' | 'expired'
  subscription_expires_at: string | null
  created_at: string
}

interface OwnerSubscriptionDetail extends OwnerSubscription {
  studios: (StudioInfo & {
    address: string | null
    room_count: number
    last_warning_at: string | null
    created_at: string
  })[]
}



/* ── Page ── */

export default function SuperAdminSubscribersPage() {
  // List state
  const [subscribers, setSubscribers] = useState<OwnerSubscription[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [total, setTotal] = useState(0)

  // Detail modal
  const [selected, setSelected] = useState<OwnerSubscriptionDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Edit subscription modal
  const [editingStudio, setEditingStudio] = useState<{ id: number; name: string; ownerName: string; status: string; expiresAt: string | null } | null>(null)
  const [editStatus, setEditStatus] = useState<'none' | 'active'>('active')
  const [editExpiresAt, setEditExpiresAt] = useState('')
  const [editLoading, setEditLoading] = useState(false)

  const fetchSubscribers = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      params.append('page', page.toString())
      if (search) params.append('search', search)
      if (statusFilter) params.append('status', statusFilter)

      const response = await api.get(`/admin/subscriptions?${params.toString()}`)
      // Axios interceptor wraps: response.data = { success, data, items, meta, pagination }
      const raw = response.data
      const items: any[] = Array.isArray(raw.items) ? raw.items : Array.isArray(raw.data) ? raw.data : []
      const meta = raw.pagination || raw.meta || { last_page: 1, total: 0 }
      setSubscribers(items)
      setTotalPages(meta.last_page || 1)
      setTotal(meta.total || 0)
    } catch (err: any) {
      console.error('Failed to fetch subscribers:', err)
    } finally {
      setLoading(false)
    }
  }, [page, search, statusFilter])

  useEffect(() => {
    fetchSubscribers()
  }, [fetchSubscribers])

  const fetchDetail = async (ownerId: number) => {
    setDetailLoading(true)
    try {
      const response = await api.get(`/admin/subscriptions/${ownerId}`)
      const raw = response.data
      setSelected((raw.data || raw) as OwnerSubscriptionDetail)
    } catch (err: any) {
      console.error('Failed to fetch detail:', err)
    } finally {
      setDetailLoading(false)
    }
  }

  const openEditModal = (studio: { id: number; name: string; ownerName: string; status: string; expiresAt: string | null }) => {
    setEditingStudio(studio)
    setEditStatus(studio.status === 'none' ? 'none' : 'active')
    if (studio.expiresAt) {
      setEditExpiresAt(studio.expiresAt.split('T')[0])
    } else {
      const nextMonth = new Date()
      nextMonth.setMonth(nextMonth.getMonth() + 1)
      setEditExpiresAt(nextMonth.toISOString().split('T')[0])
    }
  }

  const handleUpdateSubscription = async () => {
    if (!editingStudio) return
    setEditLoading(true)
    try {
      await api.post(`/studios/${editingStudio.id}/subscription`, {
        status: editStatus,
        expires_at: editStatus === 'active' ? editExpiresAt : null,
      })
      setEditingStudio(null)
      await fetchSubscribers()
      if (selected) fetchDetail(selected.id)
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal memperbarui langganan')
    } finally {
      setEditLoading(false)
    }
  }

  const formatDate = (iso: string | null) => {
    if (!iso) return '-'
    return new Date(iso).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })
  }

  const getStatusBadge = (status: string) => {
    const map: Record<string, string> = {
      none:    'bg-white/5 text-gray-400 border border-white/10',
      active:  'bg-[#48bb78]/10 text-[#48bb78] border border-[#48bb78]/20',
      expired: 'bg-[#e53e3e]/10 text-[#e53e3e] border border-[#e53e3e]/20',
    }
    return map[status] || ''
  }

  const getStatusLabel = (status: string) => {
    const map: Record<string, string> = {
      none:    'Tidak Aktif',
      active:  'Aktif',
      expired: 'Expired',
    }
    return map[status] || status
  }

  const getDaysUntilExpiry = (expiresAt: string | null) => {
    if (!expiresAt) return null
    const expiry = new Date(expiresAt)
    const now = new Date()
    const diff = Math.ceil((expiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24))
    return diff
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-black tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
            SUBSCRIBERS
          </h1>
          <p className="text-gray-500 mt-1 text-sm tracking-wide">
            Semua owner studio yang berlangganan ke platform
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { label: 'TOTAL OWNER', value: total, icon: '👥', color: 'text-blue-400', bg: 'bg-blue-500/10' },
            { label: 'AKTIF', value: subscribers.filter(s => s.subscription_status === 'active').length, icon: '✅', color: 'text-[#48bb78]', bg: 'bg-[#48bb78]/10' },
            { label: 'EXPIRED', value: subscribers.filter(s => s.subscription_status === 'expired').length, icon: '⚠️', color: 'text-[#e53e3e]', bg: 'bg-[#e53e3e]/10' },
            { label: 'TIDAK AKTIF', value: subscribers.filter(s => s.subscription_status === 'none').length, icon: '❌', color: 'text-gray-400', bg: 'bg-white/5' },
          ].map((stat, i) => (
            <div key={stat.label} className={`bg-[#0d0d0d] border border-white/5 rounded p-4 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-gray-500 text-[0.65rem] font-semibold tracking-widest uppercase">{stat.label}</p>
                  <p className="text-2xl font-black text-white mt-1.5">{stat.value}</p>
                </div>
                <div className={`w-9 h-9 rounded ${stat.bg} flex items-center justify-center text-sm`}>
                  {stat.icon}
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div className="flex flex-wrap gap-3 animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Cari nama owner / email..."
            className="flex-1 min-w-[180px] max-w-xs px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none transition-colors"
          />
          <select
            value={statusFilter}
            onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
            className="px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none"
          >
            <option value="">Semua Status</option>
            <option value="active">Aktif</option>
            <option value="expired">Expired</option>
            <option value="none">Tidak Aktif</option>
          </select>
          <div className="ml-auto text-gray-500 text-xs flex items-center">
            Total: {total} owner
          </div>
        </div>

        {/* Table */}
        <div className="bg-[#0d0d0d] border border-white/5 rounded overflow-hidden animate-fade-in-up stagger-2">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/5">
                  <th className="text-left text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Owner</th>
                  <th className="text-left text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Studio</th>
                  <th className="text-left text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Status</th>
                  <th className="text-left text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Expires</th>
                  <th className="text-left text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Sisa Hari</th>
                  <th className="text-right text-gray-500 text-[0.68rem] font-bold tracking-widest uppercase px-4 py-3">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-white/5">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center">
                      <div className="flex flex-col items-center gap-3">
                        <div className="w-8 h-8 border-2 border-[#e53e3e]/30 border-t-[#e53e3e] rounded-full animate-spin" />
                        <p className="text-gray-500 text-sm">Memuat data...</p>
                      </div>
                    </td>
                  </tr>
                ) : subscribers.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-16 text-center text-gray-500 text-sm">
                      Tidak ada data ditemukan
                    </td>
                  </tr>
                ) : (
                  subscribers.map((sub) => {
                    const daysLeft = getDaysUntilExpiry(sub.subscription_expires_at)
                    return (
                      <tr key={sub.id} className="hover:bg-[#111] transition-colors">
                        <td className="px-4 py-3">
                          <button onClick={() => fetchDetail(sub.id)} className="text-white text-sm font-semibold hover:text-[#e53e3e] transition-colors text-left">
                            {sub.owner?.name || '-'}
                          </button>
                          <p className="text-gray-500 text-xs">{sub.owner?.email || '-'}</p>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex flex-wrap gap-1">
                            {sub.studios?.slice(0, 2).map((studio) => (
                              <span key={studio.id} className={`inline-flex items-center px-2 py-0.5 text-[0.6rem] font-semibold rounded ${
                                studio.subscription_status === 'active' ? 'bg-[#48bb78]/10 text-[#48bb78]' :
                                studio.subscription_status === 'expired' ? 'bg-[#e53e3e]/10 text-[#e53e3e]' :
                                'bg-white/5 text-gray-400'
                              }`}>
                                {studio.name}
                              </span>
                            ))}
                            {sub.studios && sub.studios.length > 2 && (
                              <span className="inline-flex items-center px-2 py-0.5 text-[0.6rem] font-semibold rounded bg-white/5 text-gray-400">
                                +{sub.studios.length - 2} lagi
                              </span>
                            )}
                            {sub.total_studios === 0 && (
                              <span className="text-gray-500 text-xs">Belum ada studio</span>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <span className={`inline-flex items-center px-2.5 py-1 text-[0.65rem] font-semibold rounded ${getStatusBadge(sub.subscription_status)}`}>
                            {getStatusLabel(sub.subscription_status)}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-gray-400 text-sm">
                          {formatDate(sub.subscription_expires_at)}
                        </td>
                        <td className="px-4 py-3">
                          {daysLeft !== null ? (
                            <span className={`text-sm font-bold ${
                              daysLeft < 0 ? 'text-[#e53e3e]' :
                              daysLeft <= 7 ? 'text-[#f6ad55]' :
                              daysLeft <= 30 ? 'text-yellow-400' :
                              'text-[#48bb78]'
                            }`}>
                              {daysLeft < 0 ? `${Math.abs(daysLeft)} hari lalu` : `${daysLeft} hari`}
                            </span>
                          ) : (
                            <span className="text-gray-500 text-sm">-</span>
                          )}
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => fetchDetail(sub.id)}
                              className="px-3 py-1.5 text-[0.65rem] font-semibold rounded bg-[#1a1a1a] text-gray-400 hover:text-white hover:bg-[#222] transition-all"
                            >
                              Detail
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })
                )}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-white/5 flex items-center justify-between">
              <p className="text-gray-500 text-xs">Halaman {page} dari {totalPages}</p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1.5 text-xs font-semibold rounded bg-[#111] border border-white/5 text-gray-400 hover:text-white hover:bg-[#1a1a1a] transition-all disabled:opacity-30"
                >
                  Sebelumnya
                </button>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1.5 text-xs font-semibold rounded bg-[#111] border border-white/5 text-gray-400 hover:text-white hover:bg-[#1a1a1a] transition-all disabled:opacity-30"
                >
                  Selanjutnya
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Detail Modal ── */}
      {(selected || detailLoading) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelected(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-3xl max-h-[85vh] overflow-y-auto bg-[#0d0d0d] border border-white/5 rounded-lg p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-white tracking-wide">Detail Owner</h2>
              <button onClick={() => setSelected(null)} className="text-gray-500 hover:text-white transition-colors p-1">✕</button>
            </div>

            {detailLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-8 h-8 border-2 border-[#e53e3e]/30 border-t-[#e53e3e] rounded-full animate-spin" />
              </div>
            ) : selected && (
              <>
                {/* Owner header */}
                <div className="flex items-start gap-4 p-4 bg-[#111] rounded border border-white/5">
                  <div className="w-14 h-14 rounded bg-[#e53e3e]/10 flex items-center justify-center border border-[#e53e3e]/10">
                    <span className="text-[#e53e3e] text-xl font-bold">{selected.owner?.name?.charAt(0)}</span>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-white font-semibold text-lg">{selected.owner?.name}</h3>
                    <p className="text-gray-400 text-sm">{selected.owner?.email}</p>
                    <p className="text-gray-500 text-xs">{selected.owner?.phone || '-'}</p>
                    <div className="flex gap-2 mt-1.5">
                      <span className={`inline-flex items-center px-2.5 py-1 text-[0.6rem] font-semibold rounded ${getStatusBadge(selected.subscription_status)}`}>
                        {getStatusLabel(selected.subscription_status)}
                      </span>
                      <span className="inline-flex items-center px-2.5 py-1 text-[0.6rem] font-semibold rounded bg-white/5 text-gray-400 border border-white/10">
                        {selected.total_studios} studio
                      </span>
                    </div>
                  </div>
                </div>

                {/* Studios list */}
                <div>
                  <h4 className="text-sm font-bold text-white mb-3 tracking-wide">DAFTAR STUDIO</h4>
                  {selected.studios && selected.studios.length > 0 ? (
                    <div className="space-y-3">
                      {selected.studios.map((studio) => {
                        const daysLeft = getDaysUntilExpiry(studio.subscription_expires_at)
                        return (
                          <div key={studio.id} className="bg-[#111] border border-white/5 rounded p-4">
                            <div className="flex items-start justify-between">
                              <div>
                                <h5 className="text-white font-semibold">{studio.name}</h5>
                                <p className="text-gray-500 text-xs">{studio.city}</p>
                                <div className="flex gap-2 mt-2">
                                  <span className={`inline-flex items-center px-2 py-0.5 text-[0.6rem] font-semibold rounded ${getStatusBadge(studio.subscription_status)}`}>
                                    {getStatusLabel(studio.subscription_status)}
                                  </span>
                                  <span className="text-gray-500 text-xs">{studio.room_count} ruangan</span>
                                </div>
                              </div>
                              <div className="text-right">
                                <p className="text-gray-500 text-xs">Expires</p>
                                <p className="text-white text-sm">{formatDate(studio.subscription_expires_at)}</p>
                                {daysLeft !== null && (
                                  <p className={`text-xs font-bold mt-1 ${
                                    daysLeft < 0 ? 'text-[#e53e3e]' :
                                    daysLeft <= 7 ? 'text-[#f6ad55]' :
                                    'text-[#48bb78]'
                                  }`}>
                                    {daysLeft < 0 ? `${Math.abs(daysLeft)} hari lalu` : `${daysLeft} hari tersisa`}
                                  </p>
                                )}
                                <button
                                  onClick={() => openEditModal({
                                    id: studio.id,
                                    name: studio.name,
                                    ownerName: selected.owner?.name || '',
                                    status: studio.subscription_status,
                                    expiresAt: studio.subscription_expires_at,
                                  })}
                                  className="mt-2 px-3 py-1 text-[0.6rem] font-semibold rounded bg-[#e53e3e]/10 text-[#e53e3e] hover:bg-[#e53e3e]/20 transition-all"
                                >
                                  Atur
                                </button>
                              </div>
                            </div>
                          </div>
                        )
                      })}
                    </div>
                  ) : (
                    <div className="bg-[#111] border border-white/5 rounded p-6 text-center">
                      <p className="text-gray-500 text-sm">Owner ini belum memiliki studio</p>
                    </div>
                  )}
                </div>

                {/* Summary */}
                <div className="bg-[#111] border border-white/5 rounded p-4">
                  <div className="grid grid-cols-3 gap-4 text-center">
                    <div>
                      <p className="text-gray-500 text-xs tracking-widest uppercase">Total Studio</p>
                      <p className="text-2xl font-black text-white mt-1">{selected.total_studios}</p>
                    </div>
                    <div>
                      <p className="text-gray-500 text-xs tracking-widest uppercase">Studio Aktif</p>
                      <p className="text-2xl font-black text-[#48bb78] mt-1">
                        {selected.studios?.filter(s => s.subscription_status === 'active').length || 0}
                      </p>
                    </div>
                    <div>
                      <p className="text-gray-500 text-xs tracking-widest uppercase">Bergabung</p>
                      <p className="text-white text-sm font-bold mt-2">{formatDate(selected.created_at)}</p>
                    </div>
                  </div>
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* ── Edit Subscription Modal ── */}
      {editingStudio && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setEditingStudio(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-sm bg-[#0d0d0d] border border-white/5 rounded-lg p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-white">Atur Langganan</h2>
              <button onClick={() => setEditingStudio(null)} className="text-gray-500 hover:text-white transition-colors p-1">✕</button>
            </div>

            <div className="text-center py-2">
              <p className="text-white font-semibold">{editingStudio.name}</p>
              <p className="text-gray-500 text-sm">{editingStudio.ownerName}</p>
            </div>

            <div className="space-y-4">
              {/* Status */}
              <div className="space-y-1.5">
                <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">STATUS</label>
                <select
                  value={editStatus}
                  onChange={(e) => setEditStatus(e.target.value as 'none' | 'active')}
                  className="w-full px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none"
                >
                  <option value="active">Aktif</option>
                  <option value="none">Tidak Aktif</option>
                </select>
              </div>

              {/* Expiry date */}
              {editStatus === 'active' && (
                <div className="space-y-1.5">
                  <label className="text-gray-400 text-xs font-semibold tracking-widest uppercase">TANGGAL KADALUARSA</label>
                  <input
                    type="date"
                    value={editExpiresAt}
                    onChange={(e) => setEditExpiresAt(e.target.value)}
                    className="w-full px-4 py-2.5 bg-[#111] border border-white/5 rounded text-white text-sm focus:border-[#e53e3e]/30 focus:outline-none"
                  />
                </div>
              )}
            </div>

            <div className="flex gap-2 justify-end pt-2">
              <button
                onClick={() => setEditingStudio(null)}
                className="px-4 py-2.5 text-sm font-semibold rounded bg-[#111] border border-white/5 text-gray-400 hover:text-white hover:bg-[#1a1a1a] transition-all"
              >
                Batal
              </button>
              <button
                onClick={handleUpdateSubscription}
                disabled={editLoading}
                className="px-4 py-2.5 text-sm font-bold rounded bg-gradient-to-r from-[#c53030] to-[#e53e3e] text-white hover:from-[#e53e3e] hover:to-[#fc8181] transition-all disabled:opacity-40"
              >
                {editLoading ? 'Menyimpan...' : 'Simpan'}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
