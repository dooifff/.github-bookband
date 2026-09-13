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
  images?: { id: number; url: string; is_primary?: boolean }[]
}

export default function CustomerStudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [city, setCity] = useState('')

  const fetchStudios = useCallback(async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams()
      if (search) params.set('search', search)
      if (city) params.set('city', city)
      const response = await api.get(`/studios?${params.toString()}`)
      setStudios(response.data?.items || response.data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch studios:', err)
      setError(err?.response?.data?.message || err?.message || 'Gagal memuat studio. Pastikan backend berjalan.')
    } finally {
      setLoading(false)
    }
  }, [search, city])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-2xl font-bold text-text-primary tracking-tight">Jelajahi Studio</h1>
          <p className="text-text-secondary mt-1.5 text-sm">Temukan dan pesan studio musik</p>
          <div className="section-line mt-2" />
        </div>

        {/* Search */}
        <div className="card-luxury p-5 animate-fade-in-up stagger-1">
          <div className="flex gap-3">
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchStudios()}
              placeholder="Cari nama studio..."
              className="input-luxury flex-1 text-sm"
            />
            <input
              type="text"
              value={city}
              onChange={(e) => setCity(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && fetchStudios()}
              placeholder="Kota..."
              className="input-luxury w-48 text-sm"
            />
          </div>
        </div>

        {/* Error */}
        {error && (
          <div className="card-luxury p-6 animate-fade-in">
            <div className="text-center">
              <p className="text-danger text-sm mb-3">{error}</p>
              <button onClick={() => { setError(''); fetchStudios(); }} className="btn-gold text-sm py-2 px-5">Coba Lagi</button>
            </div>
          </div>
        )}

        {/* Studios */}
        {loading ? (
          <div className="flex items-center justify-center py-16">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Memuat studio...</p>
            </div>
          </div>
        ) : studios.length === 0 ? (
          <div className="card-luxury p-12 text-center animate-fade-in">
            <span className="text-4xl mb-4 block opacity-40">🔍</span>
            <p className="text-text-muted text-sm">Tidak ada studio ditemukan</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {studios.map((studio, i) => (
              <a
                key={studio.id}
                href={`/customer/studios/${studio.slug}`}
                className={`card-luxury overflow-hidden group animate-fade-in-up stagger-${Math.min(i + 1, 8)} hover:border-accent/20 hover:shadow-lg hover:shadow-accent/5 transition-all duration-300`}
              >
                {/* Studio Image */}
                <div className="h-44 relative overflow-hidden">
                  {studio.images && studio.images.length > 0 ? (
                    <img
                      src={studio.images[0].url}
                      alt={studio.name}
                      loading="lazy"
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                    />
                  ) : (
                    <div className="w-full h-full bg-gradient-to-br from-accent/5 via-accent/[0.02] to-transparent" />
                  )}
                  {studio.is_verified && (
                    <div className="absolute top-3 left-3 px-2.5 py-1 bg-accent/20 backdrop-blur-md border border-accent/25 rounded-full text-accent text-[0.6rem] font-semibold flex items-center gap-1">
                      <span className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse" />
                      Terverifikasi
                    </div>
                  )}
                </div>
                <div className="p-4">
                  <h3 className="text-text-primary font-bold text-sm mb-1.5 group-hover:text-accent transition-colors">{studio.name}</h3>
                  <p className="text-text-muted text-xs mb-3">📍 {studio.city}{studio.province ? `, ${studio.province}` : ''}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <span className="text-warning text-xs">★</span>
                      <span className="text-text-primary text-sm font-bold">{studio.average_rating}</span>
                      <span className="text-text-muted text-xs">({studio.total_reviews})</span>
                    </div>
                    <span className="btn-gold text-[0.65rem] py-1.5 px-4 font-semibold">
                      Lihat & Book
                    </span>
                  </div>
                </div>
              </a>
            ))}
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
