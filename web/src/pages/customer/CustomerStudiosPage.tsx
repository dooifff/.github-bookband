import { useState, useEffect } from 'react'
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

export default function CustomerStudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [city, setCity] = useState('')

  useEffect(() => {
    fetchStudios()
  }, [search, city])

  const fetchStudios = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (search) params.set('search', search)
      if (city) params.set('city', city)
      const response = await api.get(`/studios?${params.toString()}`)
      setStudios(response.data.data || [])
    } catch (error) {
      console.error('Failed to fetch studios:', error)
    } finally {
      setLoading(false)
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Browse Studios</h1>
          <p className="text-text-secondary">Find and book music studios</p>
        </div>

        {/* Search */}
        <div className="flex gap-3">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search studios..."
            className="flex-1 bg-surface-light border border-border rounded-lg px-4 py-2.5 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent"
          />
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="Filter by city..."
            className="w-48 bg-surface-light border border-border rounded-lg px-4 py-2.5 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent"
          />
        </div>

        {/* Studios Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="text-accent animate-pulse">Loading studios...</div>
          </div>
        ) : studios.length === 0 ? (
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <span className="text-4xl mb-4 block">🔍</span>
            <p className="text-text-muted text-lg">No studios found</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {studios.map((studio) => (
              <div key={studio.id} className="bg-surface border border-border rounded-xl overflow-hidden hover:shadow-lg transition-shadow">
                <div className="h-48 bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center">
                  <span className="text-5xl">🎵</span>
                </div>
                <div className="p-5">
                  <div className="flex items-start justify-between mb-2">
                    <h3 className="text-text-primary font-semibold">{studio.name}</h3>
                    {studio.is_verified && (
                      <span className="text-accent text-sm" title="Verified">✓</span>
                    )}
                  </div>
                  <p className="text-text-muted text-sm mb-3">📍 {studio.city}, {studio.province}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1">
                      <span className="text-warning">⭐</span>
                      <span className="text-text-primary text-sm">{studio.average_rating}</span>
                      <span className="text-text-muted text-sm">({studio.total_reviews})</span>
                    </div>
                    <a
                      href={`http://localhost:5173/studios/${studio.slug}`}
                      target="_blank"
                      className="px-3 py-1.5 bg-accent text-primary text-sm rounded-lg hover:bg-accent-hover transition-colors"
                    >
                      View
                    </a>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
