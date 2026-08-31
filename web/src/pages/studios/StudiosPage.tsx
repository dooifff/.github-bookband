import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Studio {
  id: number
  name: string
  slug: string
  city: string
  is_verified: boolean
  is_active: boolean
  average_rating: number
  total_reviews: number
  rooms_count: number
}

export default function StudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  const fetchStudios = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get(`/admin/studios?page=${page}`)
      setStudios(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch studios:', error)
    } finally {
      setLoading(false)
    }
  }, [page])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  const filteredStudios = studios.filter(s =>
    s.name.toLowerCase().includes(search.toLowerCase()) ||
    s.city.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Studio</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola semua studio di platform</p>
        </div>

        {/* Search */}
        <div className="animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari studio..."
            className="input-luxury text-sm w-80"
          />
        </div>

        {/* Table */}
        <div className="card-luxury overflow-hidden animate-fade-in-up stagger-2">
          <div className="overflow-x-auto">
            <table className="w-full table-luxury">
              <thead>
                <tr>
                  <th>Studio</th>
                  <th>City</th>
                  <th>Rooms</th>
                  <th>Rating</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {loading ? (
                  <tr><td colSpan={5} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-sm">Memuat studio...</p>
                    </div>
                  </td></tr>
                ) : filteredStudios.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-16 text-center text-text-muted text-sm">Tidak ada studio ditemukan</td></tr>
                ) : (
                  filteredStudios.map((studio) => (
                    <tr key={studio.id}>
                      <td>
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center text-sm">🏠</div>
                          <div>
                            <p className="text-text-primary text-sm font-medium">{studio.name}</p>
                            {studio.is_verified && <span className="text-accent text-[0.6rem]">✓ Terverifikasi</span>}
                          </div>
                        </div>
                      </td>
                      <td className="text-text-secondary text-sm">{studio.city}</td>
                      <td className="text-text-primary text-sm">{studio.rooms_count}</td>
                      <td>
                        <div className="flex items-center gap-1">
                          <span className="text-warning text-xs">★</span>
                          <span className="text-text-primary text-sm">{studio.average_rating}</span>
                          <span className="text-text-muted text-xs">({studio.total_reviews})</span>
                        </div>
                      </td>
                      <td>
                        <span className={`badge ${studio.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                          {studio.is_active ? 'Aktif' : 'Nonaktif'}
                        </span>
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
    </AdminLayout>
  )
}
