import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Studio {
  id: number
  name: string
  slug: string
  city: string
  province: string
  is_active: boolean
  is_verified: boolean
  average_rating: number
  total_reviews: number
  rooms_count: number
  created_at: string
}

export default function OwnerStudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [creating, setCreating] = useState(false)
  const [formData, setFormData] = useState({ name: '', address: '', city: '', province: '', phone: '', email: '' })

  const fetchStudios = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.get('/owner/studios')
      const data = response.data.data
      setStudios(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch studios:', err)
      setError(err.response?.data?.message || 'Gagal memuat studio')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  const handleCreateStudio = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreating(true)
    try {
      await api.post('/owner/studios', formData)
      setShowCreateModal(false)
      setFormData({ name: '', address: '', city: '', province: '', phone: '', email: '' })
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal membuat studio')
    } finally {
      setCreating(false)
    }
  }

  const handleDeleteStudio = async (studioId: number) => {
    if (!confirm('Apakah Anda yakin ingin menghapus studio ini?')) return
    try { await api.delete(`/owner/studios/${studioId}`); fetchStudios() } catch (err: any) { alert(err.response?.data?.message || 'Failed to delete studio') }
  }

  if (error && studios.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div className="animate-fade-in-up">
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Studio Saya</h1>
            <p className="text-text-secondary mt-1 text-sm">Kelola studio Anda</p>
          </div>
          <div className="card-luxury p-12 text-center">
            <p className="text-danger mb-4">{error}</p>
            <button onClick={fetchStudios} className="btn-gold text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between animate-fade-in-up">
          <div>
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Studio Saya</h1>
            <p className="text-text-secondary mt-1 text-sm">Kelola studio Anda</p>
          </div>
          <button onClick={() => setShowCreateModal(true)} className="btn-gold text-sm">+ Tambah Studio</button>
        </div>

        {/* Studios */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="flex flex-col items-center gap-4">
              <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Memuat studio...</p>
            </div>
          </div>
        ) : studios.length === 0 ? (
          <div className="card-luxury p-16 text-center animate-fade-in">
            <span className="text-4xl mb-4 block">🏠</span>
            <h3 className="text-lg font-semibold text-text-primary mb-2">Belum ada studio</h3>
            <p className="text-text-muted text-sm mb-5">Buat studio pertama Anda untuk mulai menerima pemesanan</p>
            <button onClick={() => setShowCreateModal(true)} className="btn-gold text-sm">+ Buat Studio</button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {studios.map((studio, i) => (
              <div key={studio.id} className={`card-luxury p-6 animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                {/* Header */}
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-text-primary font-semibold">{studio.name}</h3>
                    <p className="text-text-muted text-xs mt-0.5">{studio.city}, {studio.province}</p>
                  </div>
                  <span className={`badge ${studio.is_verified ? 'bg-success/10 text-success border border-success/20' : 'bg-warning/10 text-warning border border-warning/20'}`}>
                    {studio.is_verified ? 'Terverifikasi' : 'Menunggu'}
                  </span>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className="text-center p-3 rounded-xl bg-surface-light/50 border border-border/30">
                    <p className="text-text-muted text-[0.65rem] font-medium uppercase">Rooms</p>
                    <p className="text-xl font-bold text-text-primary mt-1">{studio.rooms_count}</p>
                  </div>
                  <div className="text-center p-3 rounded-xl bg-surface-light/50 border border-border/30">
                    <p className="text-text-muted text-[0.65rem] font-medium uppercase">Rating</p>
                    <div className="flex items-center justify-center gap-1 mt-1">
                      <span className="text-warning text-xs">★</span>
                      <p className="text-xl font-bold text-text-primary">{studio.average_rating?.toFixed(1) || '0.0'}</p>
                    </div>
                  </div>
                </div>

                {/* Info & Status */}
                <div className="flex items-center justify-between text-xs mb-4">
                  <span className="text-text-muted">{studio.total_reviews} ulasan</span>
                  <span className={`badge ${studio.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                    {studio.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                {/* Actions */}
                <div className="flex gap-2">
                  <button className="flex-1 btn-glass text-xs py-2">Edit</button>
                  <button className="flex-1 btn-glass text-xs py-2">Ruangan</button>
                  <button onClick={() => handleDeleteStudio(studio.id)} className="px-3 py-2 bg-danger/10 border border-danger/20 rounded-xl text-danger hover:bg-danger/15 transition-colors text-sm">🗑️</button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Create Modal */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
            <div className="glass-strong rounded-2xl p-8 w-full max-w-md mx-4 luxury-shadow-lg animate-scale-in">
              <h2 className="text-xl font-semibold text-text-primary mb-6">Buat Studio Baru</h2>
              <form onSubmit={handleCreateStudio} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Studio *</label>
                  <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="input-luxury w-full text-sm" required />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Alamat *</label>
                  <input type="text" value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} className="input-luxury w-full text-sm" required />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kota *</label>
                    <input type="text" value={formData.city} onChange={(e) => setFormData({ ...formData, city: e.target.value })} className="input-luxury w-full text-sm" required />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Provinsi *</label>
                    <input type="text" value={formData.province} onChange={(e) => setFormData({ ...formData, province: e.target.value })} className="input-luxury w-full text-sm" required />
                  </div>
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Telepon</label>
                  <input type="tel" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
                  <input type="email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="divider-gold my-2" />
                <div className="flex gap-3 pt-2">
                  <button type="button" onClick={() => setShowCreateModal(false)} className="flex-1 btn-glass text-sm py-2.5">Batal</button>
                  <button type="submit" disabled={creating} className="flex-1 btn-gold text-sm py-2.5 disabled:opacity-40">{creating ? 'Membuat...' : 'Buat Studio'}</button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
