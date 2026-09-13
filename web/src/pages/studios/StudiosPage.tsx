import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Subscription {
  status: 'none' | 'active' | 'expired' | 'removed'
  expires_at: string | null
  warning_level: number
  last_warning_at: string | null
}

interface Studio {
  id: number
  name: string
  slug: string
  city: string
  address: string
  owner: { id: number; name: string; email: string }
  is_verified: boolean
  is_active: boolean
  average_rating: number
  total_reviews: number
  rooms_count: number
  subscription?: Subscription
  created_at: string
}

interface StudioDetail extends Studio {
  description: string
  province: string
  phone: string
  email: string
  latitude: number
  longitude: number
  rooms: { id: number; name: string; price_per_hour: number; capacity: number }[]
  images: { id: number; url: string }[]
}

export default function StudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  // Detail modal
  const [selectedStudio, setSelectedStudio] = useState<StudioDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Action loading
  const [actionLoading, setActionLoading] = useState(false)

  // Subscription modal
  const [subStudio, setSubStudio] = useState<Studio | null>(null)
  const [subStatus, setSubStatus] = useState<'active' | 'none'>('active')
  const [subDate, setSubDate] = useState('')
  const [subSaving, setSubSaving] = useState(false)

  const fetchStudios = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      params.append('page', page.toString())
      if (search) params.append('search', search)
      if (statusFilter) {
        if (statusFilter === 'verified') params.append('is_verified', '1')
        else if (statusFilter === 'unverified') params.append('is_verified', '0')
        else if (statusFilter === 'active') params.append('is_active', '1')
        else if (statusFilter === 'inactive') params.append('is_active', '0')
      }
      const response = await api.get(`/admin/studios?${params.toString()}`)
      setStudios(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch studios:', error)
    } finally {
      setLoading(false)
    }
  }, [page, search, statusFilter])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  // Fetch studio detail
  const fetchStudioDetail = async (studioId: number) => {
    setDetailLoading(true)
    try {
      const response = await api.get(`/admin/studios/${studioId}`)
      setSelectedStudio(response.data.data)
    } catch (error) {
      console.error('Failed to fetch studio detail:', error)
    } finally {
      setDetailLoading(false)
    }
  }

  // Toggle verify
  const toggleVerify = async (studio: Studio) => {
    const action = studio.is_verified ? 'unverify' : 'verify'
    if (!confirm(`${studio.is_verified ? 'Batalkan verifikasi' : 'Verifikasi'} studio "${studio.name}"?`)) return
    setActionLoading(true)
    try {
      await api.post(`/admin/studios/${studio.id}/${action}`)
      await fetchStudios()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal mengubah verifikasi')
    } finally {
      setActionLoading(false)
    }
  }

  // Toggle active
  const toggleActive = async (studio: Studio) => {
    const action = studio.is_active ? 'deactivate' : 'activate'
    if (!confirm(`${studio.is_active ? 'Nonaktifkan' : 'Aktifkan'} studio "${studio.name}"?`)) return
    setActionLoading(true)
    try {
      await api.post(`/admin/studios/${studio.id}/${action}`)
      await fetchStudios()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal mengubah status')
    } finally {
      setActionLoading(false)
    }
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const subscriptionLabel = (sub?: Subscription): { text: string; color: string } => {
    if (!sub || sub.status === 'none') return { text: 'Tanpa langganan', color: 'bg-surface-lighter/60 text-text-muted border border-border/40' }
    if (sub.status === 'removed') return { text: 'Dihapus (langganan)', color: 'bg-danger/10 text-danger border border-danger/20' }
    if (sub.status === 'expired') {
      const level = sub.warning_level || 0
      if (level >= 2) return { text: '⚠️ Peringatan akhir - akan dihapus', color: 'bg-danger/10 text-danger border border-danger/20' }
      if (level >= 1) return { text: '⚠️ Peringatan 1 terkirim', color: 'bg-warning/10 text-warning border border-warning/20' }
      return { text: 'Masa aktif berakhir', color: 'bg-warning/10 text-warning border border-warning/20' }
    }
    const exp = sub.expires_at ? new Date(sub.expires_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '–'
    return { text: `Langganan s.d. ${exp}`, color: 'bg-success/10 text-success border border-success/20' }
  }

  // Open subscription modal
  const openSubscriptionModal = (studio: Studio) => {
    const sub = studio.subscription
    setSubStudio(studio)
    if (sub && sub.status !== 'none') {
      setSubStatus('active')
      setSubDate(sub.expires_at ? sub.expires_at.slice(0, 10) : '')
    } else {
      const d = new Date()
      d.setDate(d.getDate() + 30)
      setSubStatus('none')
      setSubDate(d.toISOString().slice(0, 10))
    }
  }

  // Save subscription
  const saveSubscription = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!subStudio) return
    setSubSaving(true)
    try {
      await api.post(`/admin/studios/${subStudio.id}/subscription`, {
        status: subStatus,
        expires_at: subStatus === 'active' ? subDate : null,
      })
      setSubStudio(null)
      await fetchStudios()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal menyimpan pengaturan langganan')
    } finally {
      setSubSaving(false)
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-2xl font-bold text-text-primary tracking-tight">Studio</h1>
          <p className="text-text-secondary mt-1.5 text-sm">Kelola semua studio di platform</p>
          <div className="section-line mt-2" />
        </div>

        {/* Filters */}
        <div className="card-luxury p-4 animate-fade-in-up stagger-1">
          <div className="flex gap-3">
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Cari studio..."
            className="input-luxury text-sm flex-1 max-w-xs"
          />
          <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }} className="select-luxury text-sm">
            <option value="">Semua Status</option>
            <option value="verified">Terverifikasi</option>
            <option value="unverified">Belum Diverifikasi</option>
            <option value="active">Aktif</option>
            <option value="inactive">Nonaktif</option>
          </select>
          </div>
        </div>

        {/* Table */}
        <div className="card-luxury overflow-hidden animate-fade-in-up stagger-2">
          <div className="overflow-x-auto">
            <table className="w-full table-luxury">
              <thead>
                <tr>
                  <th className="!pl-6">Studio</th>
                  <th>Owner</th>
                  <th>Kota</th>
                  <th>Rating</th>
                  <th>Status</th>
                  <th className="!pr-6">Aksi</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {loading ? (
                  <tr><td colSpan={6} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-sm">Memuat studio...</p>
                    </div>
                  </td></tr>
                ) : studios.length === 0 ? (
                  <tr><td colSpan={6} className="px-6 py-16 text-center text-text-muted text-sm">Tidak ada studio ditemukan</td></tr>
                ) : (
                  studios.map((studio) => (
                    <tr key={studio.id}>
                      <td>
                        <div className="flex items-center gap-3 pl-0">
                          <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center text-sm">🏠</div>
                          <div>
                            <button onClick={() => fetchStudioDetail(studio.id)} className="text-text-primary text-sm font-medium hover:text-accent transition-colors text-left">
                              {studio.name}
                            </button>
                            <p className="text-text-muted text-xs">{studio.rooms_count} ruangan</p>
                          </div>
                        </div>
                      </td>
                      <td className="text-text-secondary text-sm">{studio.owner?.name || '-'}</td>
                      <td className="text-text-secondary text-sm">{studio.city}</td>
                      <td>
                        <div className="flex items-center gap-1">
                          <span className="text-warning text-xs">★</span>
                          <span className="text-text-primary text-sm">{studio.average_rating}</span>
                          <span className="text-text-muted text-xs">({studio.total_reviews})</span>
                        </div>
                      </td>
                      <td>
                        <div className="flex flex-col gap-1">
                          <span className={`badge text-[0.6rem] ${studio.is_verified ? 'bg-accent/10 text-accent border border-accent/20' : 'bg-warning/10 text-warning border border-warning/20'}`}>
                            {studio.is_verified ? '✓ Terverifikasi' : '⏳ Belum Verified'}
                          </span>
                          <span className={`badge text-[0.6rem] ${studio.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                            {studio.is_active ? 'Aktif' : 'Nonaktif'}
                          </span>
                          {(() => {
                            const sub = subscriptionLabel(studio.subscription)
                            return (
                              <span className={`badge text-[0.6rem] ${sub.color}`}>
                                {sub.text}
                              </span>
                            )
                          })()}
                        </div>
                      </td>
                      <td>
                        <div className="flex items-center gap-1.5">
                          <button
                            onClick={() => fetchStudioDetail(studio.id)}
                            className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-surface-lighter/60 text-text-secondary hover:text-text-primary hover:bg-surface-light transition-all"
                          >
                            Detail
                          </button>
                          <button
                            onClick={() => toggleVerify(studio)}
                            disabled={actionLoading}
                            className={`px-2.5 py-1 text-[0.65rem] font-medium rounded-lg transition-all disabled:opacity-40 ${
                              studio.is_verified
                                ? 'bg-warning/10 text-warning hover:bg-warning/20'
                                : 'bg-accent/10 text-accent hover:bg-accent/20'
                            }`}
                          >
                            {studio.is_verified ? 'Unverify' : 'Verify'}
                          </button>
                          <button
                            onClick={() => toggleActive(studio)}
                            disabled={actionLoading}
                            className={`px-2.5 py-1 text-[0.65rem] font-medium rounded-lg transition-all disabled:opacity-40 ${
                              studio.is_active
                                ? 'bg-danger/10 text-danger hover:bg-danger/20'
                                : 'bg-success/10 text-success hover:bg-success/20'
                            }`}
                          >
                            {studio.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                          </button>
                          <button
                            onClick={() => openSubscriptionModal(studio)}
                            className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-surface-lighter/60 text-accent hover:bg-accent/10 transition-all"
                          >
                            Langganan
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-border/40 flex items-center justify-between">
              <p className="text-text-muted text-xs">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Sebelumnya</button>
                <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Selanjutnya</button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ─── Studio Detail Modal ─── */}
      {(selectedStudio || detailLoading) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedStudio(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-2xl max-h-[85vh] overflow-y-auto glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Detail Studio</h2>
              <button onClick={() => setSelectedStudio(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            {detailLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              </div>
            ) : selectedStudio && (
              <>
                {/* Header */}
                <div className="flex items-start gap-4 p-4 bg-surface-light/50 rounded-xl">
                  <div className="w-14 h-14 rounded-xl bg-accent/10 flex items-center justify-center text-2xl flex-shrink-0">🏠</div>
                  <div className="flex-1">
                    <h3 className="text-text-primary font-semibold text-lg">{selectedStudio.name}</h3>
                    <p className="text-text-secondary text-sm">{selectedStudio.address}, {selectedStudio.city}</p>
                    <div className="flex gap-2 mt-1.5">
                      {selectedStudio.is_verified && <span className="badge bg-accent/10 text-accent text-[0.6rem]">✓ Terverifikasi</span>}
                      <span className={`badge text-[0.6rem] ${selectedStudio.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                        {selectedStudio.is_active ? 'Aktif' : 'Nonaktif'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Info Grid */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs">Pemilik</p>
                    <p className="text-text-primary text-sm font-medium">{selectedStudio.owner?.name}</p>
                    <p className="text-text-muted text-xs">{selectedStudio.owner?.email}</p>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs">Rating</p>
                    <div className="flex items-center gap-1.5 mt-1">
                      <span className="text-warning text-sm">★</span>
                      <span className="text-text-primary text-sm font-semibold">{selectedStudio.average_rating}</span>
                      <span className="text-text-muted text-xs">({selectedStudio.total_reviews} ulasan)</span>
                    </div>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs">Telepon</p>
                    <p className="text-text-primary text-sm">{selectedStudio.phone || '-'}</p>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs">Email</p>
                    <p className="text-text-primary text-sm">{selectedStudio.email || '-'}</p>
                  </div>
                </div>

                {/* Description */}
                {selectedStudio.description && (
                  <div>
                    <h4 className="text-sm font-semibold text-text-primary mb-2">Deskripsi</h4>
                    <p className="text-text-secondary text-sm leading-relaxed bg-surface-light/50 rounded-xl p-3">{selectedStudio.description}</p>
                  </div>
                )}

                {/* Rooms */}
                {selectedStudio.rooms && selectedStudio.rooms.length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-text-primary mb-2">Ruangan ({selectedStudio.rooms.length})</h4>
                    <div className="space-y-2">
                      {selectedStudio.rooms.map((room) => (
                        <div key={room.id} className="flex items-center justify-between p-3 bg-surface-light/50 rounded-xl">
                          <div>
                            <p className="text-text-primary text-sm font-medium">{room.name}</p>
                            <p className="text-text-muted text-xs">Kapasitas: {room.capacity} orang</p>
                          </div>
                          <p className="text-accent text-sm font-semibold">{formatCurrency(room.price_per_hour)}/jam</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Action Buttons */}
                <div className="flex gap-2 pt-2">
                  <button
                    onClick={() => { toggleVerify(selectedStudio); setSelectedStudio(null) }}
                    disabled={actionLoading}
                    className={`flex-1 py-2.5 text-sm font-medium rounded-xl transition-all disabled:opacity-40 ${
                      selectedStudio.is_verified
                        ? 'bg-warning/10 text-warning hover:bg-warning/20 border border-warning/20'
                        : 'btn-gold'
                    }`}
                  >
                    {selectedStudio.is_verified ? 'Batalkan Verifikasi' : '✓ Verifikasi Studio'}
                  </button>
                  <button
                    onClick={() => { toggleActive(selectedStudio); setSelectedStudio(null) }}
                    disabled={actionLoading}
                    className={`flex-1 py-2.5 text-sm font-medium rounded-xl transition-all disabled:opacity-40 ${
                      selectedStudio.is_active
                        ? 'bg-danger/10 text-danger hover:bg-danger/20 border border-danger/20'
                        : 'bg-success/10 text-success hover:bg-success/20 border border-success/20'
                    }`}
                  >
                    {selectedStudio.is_active ? 'Nonaktifkan Studio' : 'Aktifkan Studio'}
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* ─── Subscription Modal ─── */}
      {subStudio && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setSubStudio(null)} />
          <div className="relative w-full max-w-md glass-strong rounded-2xl p-6 space-y-5 luxury-shadow-lg animate-scale-in">
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Atur Langganan Studio</h2>
              <button onClick={() => setSubStudio(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            <p className="text-text-secondary text-sm -mt-2">
              <span className="font-semibold text-text-primary">{subStudio.name}</span> · Owner: {subStudio.owner?.name || '-'}
            </p>

            {subStudio.subscription && subStudio.subscription.status !== 'none' && (
              <div className="bg-surface-light/50 rounded-xl p-3 text-xs space-y-1">
                <p className="text-text-muted">
                  Status: <span className="font-semibold text-text-primary capitalize">{subStudio.subscription.status}</span>
                  {subStudio.subscription.warning_level > 0 && ` · Peringatan ${subStudio.subscription.warning_level} terkirim`}
                </p>
                {subStudio.subscription.expires_at && (
                  <p className="text-text-muted">
                    Berakhir: <span className="text-text-primary font-medium">
                      {new Date(subStudio.subscription.expires_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' })}
                    </span>
                  </p>
                )}
              </div>
            )}

            <form onSubmit={saveSubscription} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Status Langganan</label>
                <select
                  value={subStatus}
                  onChange={(e) => setSubStatus(e.target.value as 'active' | 'none')}
                  className="select-luxury w-full text-sm"
                >
                  <option value="active">Berlangganan (aktif)</option>
                  <option value="none">Tidak berlangganan</option>
                </select>
              </div>

              {subStatus === 'active' && (
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Masa Aktif Berakhir Pada *</label>
                  <input
                    type="date"
                    value={subDate}
                    onChange={(e) => setSubDate(e.target.value)}
                    className="input-luxury w-full text-sm"
                    required
                  />
                  <p className="text-text-muted text-[0.65rem]">
                    Pilih tanggal hari ini atau kemarin untuk langsung menguji cron peringatan (status jadi expired).
                  </p>
                </div>
              )}

              <div className="flex gap-3 pt-2">
                <button type="button" onClick={() => setSubStudio(null)} className="flex-1 btn-glass text-sm py-2.5">Batal</button>
                <button type="submit" disabled={subSaving} className="flex-1 btn-gold text-sm py-2.5 disabled:opacity-40">
                  {subSaving ? 'Menyimpan...' : 'Simpan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
