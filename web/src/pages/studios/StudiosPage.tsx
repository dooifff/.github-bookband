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
  created_at: string
}

export default function StudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalCount, setTotalCount] = useState(0)

  useEffect(() => {
    fetchStudios()
  }, [page, search, statusFilter])

  const fetchStudios = async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (search) params.append('search', search)
      if (statusFilter) params.append('status', statusFilter)
      params.append('page', page.toString())

      const response = await api.get(`/admin/studios?${params.toString()}`)
      // Backend paginated response: { success, message, data: [...], meta: { current_page, last_page, per_page, total } }
      setStudios(response.data.data || [])
      setTotalPages(response.data.meta?.last_page || 1)
      setTotalCount(response.data.meta?.total || 0)
    } catch (err: any) {
      console.error('Failed to fetch studios:', err)
      setError(err.response?.data?.message || 'Failed to load studios')
      setStudios([])
    } finally {
      setLoading(false)
    }
  }

  const handleVerify = async (studioId: number) => {
    try {
      await api.post(`/admin/studios/${studioId}/verify`)
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to verify studio:', err)
    }
  }

  const handleUnverify = async (studioId: number) => {
    try {
      await api.post(`/admin/studios/${studioId}/unverify`)
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to unverify studio:', err)
    }
  }

  const handleActivate = async (studioId: number) => {
    try {
      await api.post(`/admin/studios/${studioId}/activate`)
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to activate studio:', err)
    }
  }

  const handleDeactivate = async (studioId: number) => {
    try {
      await api.post(`/admin/studios/${studioId}/deactivate`)
      fetchStudios()
    } catch (err: any) {
      console.error('Failed to deactivate studio:', err)
    }
  }

  if (error && studios.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Studios</h1>
            <p className="text-text-secondary">Manage studios on the platform</p>
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
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Studios</h1>
          <p className="text-text-secondary">Manage studios on the platform ({totalCount} total)</p>
        </div>

        {/* Filters */}
        <div className="bg-surface border border-border rounded-xl p-4">
          <div className="flex flex-wrap gap-4">
            <div className="flex-1 min-w-[200px]">
              <input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                placeholder="Search studios..."
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent"
              />
            </div>
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
            >
              <option value="">All Status</option>
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="verified">Verified</option>
              <option value="pending">Pending Verification</option>
            </select>
          </div>
        </div>

        {/* Studios Table */}
        <div className="bg-surface border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-surface-light">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Studio</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Location</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Rating</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-text-muted">
                      <div className="animate-pulse">Loading studios...</div>
                    </td>
                  </tr>
                ) : studios.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-text-muted">
                      <p className="text-lg mb-2">No studios found</p>
                      <p className="text-sm">Try adjusting your search</p>
                    </td>
                  </tr>
                ) : (
                  studios.map((studio) => (
                    <tr key={studio.id} className="hover:bg-surface-light/50 transition-colors">
                      <td className="px-6 py-4">
                        <div>
                          <p className="text-text-primary font-medium">{studio.name}</p>
                          <p className="text-text-muted text-sm">/{studio.slug}</p>
                        </div>
                      </td>
                      <td className="px-6 py-4 text-text-secondary text-sm">
                        {studio.city}, {studio.province}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-1">
                          <span className="text-warning">⭐</span>
                          <span className="text-text-primary">{studio.average_rating?.toFixed(1) || '0.0'}</span>
                          <span className="text-text-muted text-sm">({studio.total_reviews})</span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex flex-col gap-1">
                          <span className={`px-2 py-1 text-xs rounded w-fit ${
                            studio.is_active ? 'bg-success/20 text-success' : 'bg-error/20 text-error'
                          }`}>
                            {studio.is_active ? 'Active' : 'Inactive'}
                          </span>
                          <span className={`px-2 py-1 text-xs rounded w-fit ${
                            studio.is_verified ? 'bg-accent/20 text-accent' : 'bg-warning/20 text-warning'
                          }`}>
                            {studio.is_verified ? 'Verified' : 'Pending'}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          {studio.is_verified ? (
                            <button
                              onClick={() => handleUnverify(studio.id)}
                              className="px-3 py-1 text-sm bg-warning/10 text-warning rounded hover:bg-warning/20 transition-colors"
                            >
                              Unverify
                            </button>
                          ) : (
                            <button
                              onClick={() => handleVerify(studio.id)}
                              className="px-3 py-1 text-sm bg-success/10 text-success rounded hover:bg-success/20 transition-colors"
                            >
                              Verify
                            </button>
                          )}
                          {studio.is_active ? (
                            <button
                              onClick={() => handleDeactivate(studio.id)}
                              className="px-3 py-1 text-sm bg-error/10 text-error rounded hover:bg-error/20 transition-colors"
                            >
                              Deactivate
                            </button>
                          ) : (
                            <button
                              onClick={() => handleActivate(studio.id)}
                              className="px-3 py-1 text-sm bg-success/10 text-success rounded hover:bg-success/20 transition-colors"
                            >
                              Activate
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-border flex items-center justify-between">
              <p className="text-text-muted text-sm">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50 transition-colors"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50 transition-colors"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  )
}
