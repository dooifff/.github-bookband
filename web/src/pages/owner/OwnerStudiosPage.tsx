import { useState, useEffect } from 'react'
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
  const [formData, setFormData] = useState({
    name: '',
    address: '',
    city: '',
    province: '',
    phone: '',
    email: '',
  })

  useEffect(() => {
    fetchStudios()
  }, [])

  const fetchStudios = async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.get('/owner/studios')
      // Owner studios endpoint may return array directly or paginated
      const data = response.data.data
      setStudios(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch studios:', err)
      setError(err.response?.data?.message || 'Failed to load studios')
    } finally {
      setLoading(false)
    }
  }

  const handleCreateStudio = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreating(true)
    try {
      await api.post('/owner/studios', formData)
      setShowCreateModal(false)
      setFormData({ name: '', address: '', city: '', province: '', phone: '', email: '' })
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to create studio:', err)
      alert(err.response?.data?.message || 'Failed to create studio')
    } finally {
      setCreating(false)
    }
  }

  const handleDeleteStudio = async (studioId: number) => {
    if (!confirm('Are you sure you want to delete this studio?')) return

    try {
      await api.delete(`/owner/studios/${studioId}`)
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to delete studio:', err)
      alert(err.response?.data?.message || 'Failed to delete studio')
    }
  }

  if (error && studios.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-2xl font-bold text-text-primary">My Studios</h1>
              <p className="text-text-secondary">Manage your studios</p>
            </div>
          </div>
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <p className="text-error mb-4">{error}</p>
            <button
              onClick={fetchStudios}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              Retry
            </button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">My Studios</h1>
            <p className="text-text-secondary">Manage your studios</p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="bg-accent hover:bg-accent-hover text-primary font-semibold px-4 py-2 rounded-lg transition-colors"
          >
            + Add Studio
          </button>
        </div>

        {/* Studios Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="text-accent animate-pulse">Loading studios...</div>
          </div>
        ) : studios.length === 0 ? (
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <span className="text-4xl mb-4 block">🏠</span>
            <h3 className="text-lg font-semibold text-text-primary mb-2">No studios yet</h3>
            <p className="text-text-muted mb-4">Create your first studio to start receiving bookings</p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="bg-accent hover:bg-accent-hover text-primary font-semibold px-4 py-2 rounded-lg transition-colors"
            >
              + Create Studio
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {studios.map((studio) => (
              <div key={studio.id} className="bg-surface border border-border rounded-xl p-6 hover:border-accent transition-colors">
                <div className="flex items-start justify-between mb-4">
                  <div>
                    <h3 className="text-lg font-semibold text-text-primary">{studio.name}</h3>
                    <p className="text-text-muted text-sm">{studio.city}, {studio.province}</p>
                  </div>
                  <div className="flex gap-2">
                    {studio.is_verified ? (
                      <span className="px-2 py-1 text-xs rounded bg-success/20 text-success">Verified</span>
                    ) : (
                      <span className="px-2 py-1 text-xs rounded bg-warning/20 text-warning">Pending</span>
                    )}
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4 mb-4">
                  <div className="text-center p-3 bg-surface-light rounded-lg">
                    <p className="text-text-muted text-xs">Rooms</p>
                    <p className="text-xl font-bold text-text-primary">{studio.rooms_count}</p>
                  </div>
                  <div className="text-center p-3 bg-surface-light rounded-lg">
                    <p className="text-text-muted text-xs">Rating</p>
                    <div className="flex items-center justify-center gap-1">
                      <span className="text-warning">⭐</span>
                      <p className="text-xl font-bold text-text-primary">{studio.average_rating?.toFixed(1) || '0.0'}</p>
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between text-sm mb-4">
                  <span className="text-text-muted">{studio.total_reviews} reviews</span>
                  <span className={`px-2 py-1 rounded ${studio.is_active ? 'bg-success/10 text-success' : 'bg-error/10 text-error'}`}>
                    {studio.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                <div className="flex gap-2">
                  <button className="flex-1 px-3 py-2 bg-surface-light border border-border rounded-lg text-text-secondary hover:text-text-primary transition-colors text-sm">
                    Edit
                  </button>
                  <button className="flex-1 px-3 py-2 bg-surface-light border border-border rounded-lg text-text-secondary hover:text-text-primary transition-colors text-sm">
                    Rooms
                  </button>
                  <button
                    onClick={() => handleDeleteStudio(studio.id)}
                    className="px-3 py-2 bg-error/10 border border-error/30 rounded-lg text-error hover:bg-error/20 transition-colors text-sm"
                  >
                    🗑️
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Create Studio Modal */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-surface border border-border rounded-xl p-6 w-full max-w-md mx-4">
              <h2 className="text-xl font-semibold text-text-primary mb-4">Create New Studio</h2>
              <form onSubmit={handleCreateStudio} className="space-y-4">
                <div>
                  <label className="block text-text-secondary text-sm mb-1">Studio Name *</label>
                  <input
                    type="text"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                    required
                  />
                </div>
                <div>
                  <label className="block text-text-secondary text-sm mb-1">Address *</label>
                  <input
                    type="text"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                    required
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <label className="block text-text-secondary text-sm mb-1">City *</label>
                    <input
                      type="text"
                      value={formData.city}
                      onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                      className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-text-secondary text-sm mb-1">Province *</label>
                    <input
                      type="text"
                      value={formData.province}
                      onChange={(e) => setFormData({ ...formData, province: e.target.value })}
                      className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                      required
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-text-secondary text-sm mb-1">Phone</label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                  />
                </div>
                <div>
                  <label className="block text-text-secondary text-sm mb-1">Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
                  />
                </div>
                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    className="flex-1 px-4 py-2 bg-surface-light border border-border rounded-lg text-text-secondary hover:text-text-primary transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={creating}
                    className="flex-1 px-4 py-2 bg-accent hover:bg-accent-hover text-primary font-semibold rounded-lg transition-colors disabled:opacity-50"
                  >
                    {creating ? 'Creating...' : 'Create Studio'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
