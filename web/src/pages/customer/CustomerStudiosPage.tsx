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

export default function CustomerStudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [city, setCity] = useState('')

  const fetchStudios = useCallback(async () => {
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
  }, [search, city])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Jelajahi Studio</h1>
          <p className="text-text-secondary mt-1 text-sm">Temukan dan pesan studio musik</p>
        </div>

        {/* Search */}
        <div className="flex gap-3 animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari studio..."
            className="input-luxury flex-1 text-sm"
          />
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            placeholder="Filter berdasarkan kota..."
            className="input-luxury w-48 text-sm"
          />
        </div>

        {/* Studios */}
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Memuat studio...</p>
            </div>
          </div>
        ) : studios.length === 0 ? (
          <div className="card-luxury p-16 text-center animate-fade-in">
            <span className="text-4xl mb-4 block">🔍</span>
            <p className="text-text-muted text-lg">Tidak ada studio ditemukan</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {studios.map((studio, i) => (
              <div key={studio.id} className={`card-luxury overflow-hidden group animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                {/* Image placeholder */}
                <div className="h-44 bg-gradient-to-br from-accent/10 via-accent/[0.03] to-transparent flex items-center justify-center relative overflow-hidden">
                  <span className="text-5xl opacity-60 group-hover:scale-110 transition-transform duration-500">🎵</span>
                  {studio.is_verified && (
                    <div className="absolute top-3 right-3 px-2 py-0.5 bg-accent/15 border border-accent/20 rounded-full text-accent text-[0.6rem] font-medium">
                      ✓ Terverifikasi
                    </div>
                  )}
                </div>
                <div className="p-5">
                  <h3 className="text-text-primary font-semibold mb-1">{studio.name}</h3>
                  <p className="text-text-muted text-xs mb-3">📍 {studio.city}, {studio.province}</p>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-1.5">
                      <span className="text-warning text-xs">★</span>
                      <span className="text-text-primary text-sm font-medium">{studio.average_rating}</span>
                      <span className="text-text-muted text-xs">({studio.total_reviews})</span>
                    </div>
                    <a
                      href={`/customer/studios/${studio.slug}`}
                      className="btn-gold text-xs py-1.5 px-4"
                    >
                      Lihat & Book
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
