import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Promo {
  id: number
  code: string
  name: string
  description: string | null
  type: 'percentage' | 'fixed'
  value: number
  min_booking_amount: number
  max_discount: number | null
  usage_limit: number | null
  usage_count: number
  per_user_limit: number
  start_date: string
  end_date: string
  is_active: boolean
  studio_id: number | null
  studio?: { id: number; name: string } | null
}

interface Studio {
  id: number
  name: string
  city: string
}

interface PromoStats {
  total: number
  active: number
  expired: number
  inactive: number
  total_usage: number
  total_discount: number
}

const emptyForm = {
  code: '',
  name: '',
  description: '',
  type: 'percentage' as 'percentage' | 'fixed',
  value: 0,
  min_booking_amount: 0,
  max_discount: null as number | null,
  usage_limit: null as number | null,
  per_user_limit: 1,
  start_date: '',
  end_date: '',
  studio_id: null as number | null,
  is_active: true,
}

export default function OwnerPromosPage() {
  const [promos, setPromos] = useState<Promo[]>([])
  const [stats, setStats] = useState<PromoStats | null>(null)
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingPromo, setEditingPromo] = useState<Promo | null>(null)
  const [form, setForm] = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState('all')
  const [filterType, setFilterType] = useState('all')
  const [currentPage, setCurrentPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  useEffect(() => {
    fetchPromos()
    fetchStats()
    fetchStudios()
  }, [currentPage, search, filterStatus, filterType])

  const fetchPromos = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams({
        page: currentPage.toString(),
        per_page: '10',
      })
      if (search) params.append('search', search)
      if (filterStatus !== 'all') params.append('status', filterStatus)
      if (filterType !== 'all') params.append('type', filterType)

      const { data } = await api.get(`/owner/promos?${params}`)
      setPromos(data.data)
      setTotalPages(data.meta.last_page)
    } catch (err) {
      console.error('Failed to fetch promos:', err)
    } finally {
      setLoading(false)
    }
  }

  const fetchStats = async () => {
    try {
      const { data } = await api.get('/owner/promos/stats')
      setStats(data.data)
    } catch (err) {
      console.error('Failed to fetch stats:', err)
    }
  }

  const fetchStudios = async () => {
    try {
      const { data } = await api.get('/owner/promos/studios')
      setStudios(data.data)
    } catch (err) {
      console.error('Failed to fetch studios:', err)
    }
  }

  const handleGenerateCode = async () => {
    try {
      const { data } = await api.get('/owner/promos/generate-code')
      setForm({ ...form, code: data.data.code })
    } catch (err) {
      console.error('Failed to generate code:', err)
    }
  }

  const openCreateModal = () => {
    setEditingPromo(null)
    setForm({ ...emptyForm, studio_id: studios.length > 0 ? studios[0].id : null })
    setShowModal(true)
  }

  const openEditModal = (promo: Promo) => {
    setEditingPromo(promo)
    setForm({
      code: promo.code,
      name: promo.name,
      description: promo.description || '',
      type: promo.type,
      value: promo.value,
      min_booking_amount: promo.min_booking_amount,
      max_discount: promo.max_discount,
      usage_limit: promo.usage_limit,
      per_user_limit: promo.per_user_limit,
      start_date: promo.start_date,
      end_date: promo.end_date,
      studio_id: promo.studio_id,
      is_active: promo.is_active,
    })
    setShowModal(true)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = {
        ...form,
        code: form.code.toUpperCase(),
        value: Number(form.value),
        min_booking_amount: Number(form.min_booking_amount),
        max_discount: form.max_discount ? Number(form.max_discount) : null,
        usage_limit: form.usage_limit ? Number(form.usage_limit) : null,
        per_user_limit: Number(form.per_user_limit),
      }

      if (editingPromo) {
        await api.put(`/owner/promos/${editingPromo.id}`, payload)
      } else {
        await api.post('/owner/promos', payload)
      }
      setShowModal(false)
      fetchPromos()
      fetchStats()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menyimpan promo')
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (promo: Promo) => {
    if (!confirm(`Hapus promo "${promo.name}" (${promo.code})?`)) return
    try {
      await api.delete(`/owner/promos/${promo.id}`)
      fetchPromos()
      fetchStats()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menghapus promo')
    }
  }

  const handleToggle = async (promo: Promo) => {
    try {
      await api.post(`/owner/promos/${promo.id}/toggle`)
      fetchPromos()
      fetchStats()
    } catch (err) {
      console.error('Failed to toggle promo:', err)
    }
  }

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString('id-ID', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    })
  }

  const formatCurrency = (amount: number) => {
    return 'Rp ' + amount.toLocaleString('id-ID')
  }

  const getStatus = (promo: Promo) => {
    if (!promo.is_active) return { label: 'Nonaktif', color: 'bg-gray-500/10 text-gray-400' }
    const now = new Date()
    const start = new Date(promo.start_date)
    const end = new Date(promo.end_date)
    if (now < start) return { label: 'Mendatang', color: 'bg-blue-500/10 text-blue-400' }
    if (now > end) return { label: 'Kadaluarsa', color: 'bg-red-500/10 text-red-400' }
    if (promo.usage_limit && promo.usage_count >= promo.usage_limit) {
      return { label: 'Habis', color: 'bg-orange-500/10 text-orange-400' }
    }
    return { label: 'Aktif', color: 'bg-green-500/10 text-green-400' }
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Kode Promo</h1>
            <p className="text-text-muted text-sm mt-1">Kelola kode diskon untuk pelanggan</p>
          </div>
          <button
            onClick={openCreateModal}
            className="btn-primary flex items-center gap-2"
          >
            <span>+</span>
            <span>Buat Promo</span>
          </button>
        </div>
        <div className="section-line" />

        {/* Stats */}
        {stats && (
          <div className="grid grid-cols-2 md:grid-cols-5 gap-4">
            <div className="card-luxury p-4">
              <p className="text-text-muted text-xs font-medium uppercase tracking-wider">Total</p>
              <p className="text-2xl font-bold text-text-primary mt-1">{stats.total}</p>
            </div>
            <div className="card-luxury p-4">
              <p className="text-text-muted text-xs font-medium uppercase tracking-wider">Aktif</p>
              <p className="text-2xl font-bold text-green-400 mt-1">{stats.active}</p>
            </div>
            <div className="card-luxury p-4">
              <p className="text-text-muted text-xs font-medium uppercase tracking-wider">Kadaluarsa</p>
              <p className="text-2xl font-bold text-red-400 mt-1">{stats.expired}</p>
            </div>
            <div className="card-luxury p-4">
              <p className="text-text-muted text-xs font-medium uppercase tracking-wider">Total Dipakai</p>
              <p className="text-2xl font-bold text-accent mt-1">{stats.total_usage}</p>
            </div>
            <div className="card-luxury p-4">
              <p className="text-text-muted text-xs font-medium uppercase tracking-wider">Total Diskon</p>
              <p className="text-2xl font-bold text-yellow-400 mt-1">{formatCurrency(stats.total_discount)}</p>
            </div>
          </div>
        )}

        {/* Filters */}
        <div className="card-luxury p-4">
          <div className="flex flex-wrap gap-4">
            <div className="flex-1 min-w-[200px]">
              <input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setCurrentPage(1) }}
                placeholder="Cari kode atau nama promo..."
                className="input-luxury w-full"
              />
            </div>
            <select
              value={filterStatus}
              onChange={(e) => { setFilterStatus(e.target.value); setCurrentPage(1) }}
              className="input-luxury"
            >
              <option value="all">Semua Status</option>
              <option value="active">Aktif</option>
              <option value="inactive">Nonaktif</option>
              <option value="expired">Kadaluarsa</option>
              <option value="upcoming">Mendatang</option>
            </select>
            <select
              value={filterType}
              onChange={(e) => { setFilterType(e.target.value); setCurrentPage(1) }}
              className="input-luxury"
            >
              <option value="all">Semua Tipe</option>
              <option value="percentage">Persen (%)</option>
              <option value="fixed">Nominal (Rp)</option>
            </select>
          </div>
        </div>

        {/* Table */}
        <div className="card-luxury overflow-hidden">
          {loading ? (
            <div className="p-12 text-center">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin mx-auto" />
              <p className="text-text-muted mt-3 text-sm">Memuat data...</p>
            </div>
          ) : promos.length === 0 ? (
            <div className="p-12 text-center">
              <div className="text-4xl mb-3 opacity-30">🏷️</div>
              <p className="text-text-muted">Belum ada promo</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead>
                  <tr className="border-b border-border/50">
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Kode</th>
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Nama</th>
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Diskon</th>
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Periode</th>
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Penggunaan</th>
                    <th className="text-left px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Status</th>
                    <th className="text-right px-5 py-3.5 text-text-muted text-xs font-semibold uppercase tracking-wider">Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {promos.map((promo) => {
                    const status = getStatus(promo)
                    return (
                      <tr key={promo.id} className="border-b border-border/30 hover:bg-surface-lighter/30 transition-colors">
                        <td className="px-5 py-4">
                          <span className="font-mono font-bold text-accent bg-accent/10 px-2.5 py-1 rounded-lg text-sm">
                            {promo.code}
                          </span>
                        </td>
                        <td className="px-5 py-4">
                          <div>
                            <p className="text-text-primary font-medium">{promo.name}</p>
                            {promo.studio && (
                              <p className="text-text-muted text-xs mt-0.5">📍 {promo.studio.name}</p>
                            )}
                          </div>
                        </td>
                        <td className="px-5 py-4">
                          <span className="text-text-primary font-semibold">
                            {promo.type === 'percentage' ? `${promo.value}%` : formatCurrency(promo.value)}
                          </span>
                        </td>
                        <td className="px-5 py-4">
                          <p className="text-text-secondary text-sm">{formatDate(promo.start_date)}</p>
                          <p className="text-text-muted text-xs">s/d {formatDate(promo.end_date)}</p>
                        </td>
                        <td className="px-5 py-4">
                          <span className="text-text-primary">
                            {promo.usage_count}
                            {promo.usage_limit ? ` / ${promo.usage_limit}` : ''}
                          </span>
                        </td>
                        <td className="px-5 py-4">
                          <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${status.color}`}>
                            <span className="w-1.5 h-1.5 rounded-full bg-current" />
                            {status.label}
                          </span>
                        </td>
                        <td className="px-5 py-4">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleToggle(promo)}
                              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors cursor-pointer ${
                                promo.is_active
                                  ? 'bg-green-500/10 text-green-400 hover:bg-green-500/20'
                                  : 'bg-gray-500/10 text-gray-400 hover:bg-gray-500/20'
                              }`}
                            >
                              {promo.is_active ? 'Aktif' : 'Nonaktif'}
                            </button>
                            <button
                              onClick={() => openEditModal(promo)}
                              className="px-3 py-1.5 rounded-lg text-xs font-medium bg-accent/10 text-accent hover:bg-accent/20 transition-colors cursor-pointer"
                            >
                              Edit
                            </button>
                            <button
                              onClick={() => handleDelete(promo)}
                              className="px-3 py-1.5 rounded-lg text-xs font-medium bg-red-500/10 text-red-400 hover:bg-red-500/20 transition-colors cursor-pointer"
                            >
                              Hapus
                            </button>
                          </div>
                        </td>
                      </tr>
                    )
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="px-5 py-4 border-t border-border/30 flex items-center justify-between">
              <p className="text-text-muted text-sm">
                Halaman {currentPage} dari {totalPages}
              </p>
              <div className="flex gap-2">
                <button
                  onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                  disabled={currentPage === 1}
                  className="btn-glass px-3 py-1.5 text-sm disabled:opacity-40"
                >
                  ← Sebelumnya
                </button>
                <button
                  onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                  disabled={currentPage === totalPages}
                  className="btn-glass px-3 py-1.5 text-sm disabled:opacity-40"
                >
                  Selanjutnya →
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Modal Create/Edit */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" onClick={() => setShowModal(false)} />
          <div className="relative w-full max-w-lg bg-secondary rounded-2xl border border-border/50 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-xl font-bold text-text-primary">
                  {editingPromo ? 'Edit Promo' : 'Buat Promo Baru'}
                </h2>
                <button
                  onClick={() => setShowModal(false)}
                  className="text-text-muted hover:text-text-primary transition-colors text-xl"
                >
                  ✕
                </button>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Code */}
                <div>
                  <label className="block text-text-secondary text-sm font-medium mb-1.5">Kode Promo</label>
                  <div className="flex gap-2">
                    <input
                      type="text"
                      value={form.code}
                      onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                      placeholder="CONTOH10"
                      className="input-luxury flex-1 font-mono uppercase"
                      required
                      maxLength={20}
                    />
                    <button
                      type="button"
                      onClick={handleGenerateCode}
                      className="btn-glass px-4 py-2 text-sm whitespace-nowrap"
                    >
                      🎲 Generate
                    </button>
                  </div>
                </div>

                {/* Name */}
                <div>
                  <label className="block text-text-secondary text-sm font-medium mb-1.5">Nama Promo</label>
                  <input
                    type="text"
                    value={form.name}
                    onChange={(e) => setForm({ ...form, name: e.target.value })}
                    placeholder="Diskon Awal Tahun"
                    className="input-luxury w-full"
                    required
                    maxLength={100}
                  />
                </div>

                {/* Description */}
                <div>
                  <label className="block text-text-secondary text-sm font-medium mb-1.5">Deskripsi</label>
                  <textarea
                    value={form.description}
                    onChange={(e) => setForm({ ...form, description: e.target.value })}
                    placeholder="Deskripsi promo (opsional)"
                    className="input-luxury w-full resize-none h-20"
                    maxLength={500}
                  />
                </div>

                {/* Type & Value */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Tipe Diskon</label>
                    <select
                      value={form.type}
                      onChange={(e) => setForm({ ...form, type: e.target.value as 'percentage' | 'fixed' })}
                      className="input-luxury w-full"
                    >
                      <option value="percentage">Persen (%)</option>
                      <option value="fixed">Nominal (Rp)</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">
                      Nilai {form.type === 'percentage' ? '(%)' : '(Rp)'}
                    </label>
                    <input
                      type="number"
                      value={form.value || ''}
                      onChange={(e) => setForm({ ...form, value: Number(e.target.value) })}
                      placeholder={form.type === 'percentage' ? '10' : '50000'}
                      className="input-luxury w-full"
                      required
                      min={0}
                      max={form.type === 'percentage' ? 100 : undefined}
                    />
                  </div>
                </div>

                {/* Min amount & Max discount */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Min. Booking (Rp)</label>
                    <input
                      type="number"
                      value={form.min_booking_amount || ''}
                      onChange={(e) => setForm({ ...form, min_booking_amount: Number(e.target.value) })}
                      placeholder="0"
                      className="input-luxury w-full"
                      min={0}
                    />
                  </div>
                  {form.type === 'percentage' && (
                    <div>
                      <label className="block text-text-secondary text-sm font-medium mb-1.5">Max. Diskon (Rp)</label>
                      <input
                        type="number"
                        value={form.max_discount || ''}
                        onChange={(e) => setForm({ ...form, max_discount: e.target.value ? Number(e.target.value) : null })}
                        placeholder="Tidak terbatas"
                        className="input-luxury w-full"
                        min={0}
                      />
                    </div>
                  )}
                </div>

                {/* Usage limit & Per user limit */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Batas Penggunaan</label>
                    <input
                      type="number"
                      value={form.usage_limit || ''}
                      onChange={(e) => setForm({ ...form, usage_limit: e.target.value ? Number(e.target.value) : null })}
                      placeholder="Tidak terbatas"
                      className="input-luxury w-full"
                      min={1}
                    />
                  </div>
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Batas per User</label>
                    <input
                      type="number"
                      value={form.per_user_limit}
                      onChange={(e) => setForm({ ...form, per_user_limit: Number(e.target.value) })}
                      className="input-luxury w-full"
                      min={1}
                    />
                  </div>
                </div>

                {/* Dates */}
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Tanggal Mulai</label>
                    <input
                      type="date"
                      value={form.start_date}
                      onChange={(e) => setForm({ ...form, start_date: e.target.value })}
                      className="input-luxury w-full"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-text-secondary text-sm font-medium mb-1.5">Tanggal Selesai</label>
                    <input
                      type="date"
                      value={form.end_date}
                      onChange={(e) => setForm({ ...form, end_date: e.target.value })}
                      className="input-luxury w-full"
                      required
                      min={form.start_date}
                    />
                  </div>
                </div>

                {/* Studio */}
                <div>
                  <label className="block text-text-secondary text-sm font-medium mb-1.5">Berlaku untuk Studio</label>
                  <select
                    value={form.studio_id || ''}
                    onChange={(e) => setForm({ ...form, studio_id: e.target.value ? Number(e.target.value) : null })}
                    className="input-luxury w-full"
                    required
                  >
                    <option value="">Pilih Studio</option>
                    {studios.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} — {s.city}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Active */}
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setForm({ ...form, is_active: !form.is_active })}
                    className={`relative w-11 h-6 rounded-full transition-colors ${
                      form.is_active ? 'bg-accent' : 'bg-surface-lighter'
                    }`}
                  >
                    <span
                      className={`absolute top-0.5 w-5 h-5 rounded-full bg-white shadow transition-transform ${
                        form.is_active ? 'translate-x-5' : 'translate-x-0.5'
                      }`}
                    />
                  </button>
                  <span className="text-text-secondary text-sm">Aktif saat dibuat</span>
                </div>

                {/* Actions */}
                <div className="flex gap-3 pt-4 border-t border-border/30">
                  <button
                    type="button"
                    onClick={() => setShowModal(false)}
                    className="btn-glass flex-1 py-2.5"
                  >
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={saving}
                    className="btn-primary flex-1 py-2.5 flex items-center justify-center gap-2"
                  >
                    {saving ? (
                      <>
                        <div className="w-4 h-4 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
                        Menyimpan...
                      </>
                    ) : editingPromo ? (
                      'Simpan Perubahan'
                    ) : (
                      'Buat Promo'
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
