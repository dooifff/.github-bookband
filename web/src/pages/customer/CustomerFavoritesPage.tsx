import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Favorite {
  id: number
  name: string
  slug: string
  city: string
  average_rating: number
  total_reviews: number
  images: { url: string; is_primary: boolean }[]
}

export default function CustomerFavoritesPage() {
  const [favorites, setFavorites] = useState<Favorite[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => { fetchFavorites() }, [])

  const fetchFavorites = async () => {
    try {
      const response = await api.get('/favorites')
      setFavorites(response.data.data || [])
    } catch (error) {
      console.error('Failed to fetch favorites:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleRemove = async (studioId: number) => {
    try {
      await api.delete(`/favorites/${studioId}`)
      setFavorites(favorites.filter(f => f.id !== studioId))
    } catch (error) {
      console.error('Failed to remove favorite:', error)
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">My Favorites</h1>
          <p className="text-text-secondary mt-1 text-sm">Studios you've saved</p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Loading favorites...</p>
            </div>
          </div>
        ) : favorites.length === 0 ? (
          <div className="card-luxury p-16 text-center animate-fade-in">
            <span className="text-4xl mb-4 block">❤️</span>
            <p className="text-text-muted text-lg">No favorites yet</p>
            <a href="/customer/studios" className="text-accent text-sm hover:text-accent-hover mt-2 inline-block transition-colors">
              Browse studios to add favorites →
            </a>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {favorites.map((fav, i) => (
              <div key={fav.id} className={`card-luxury p-5 animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                <div className="flex items-center gap-3 mb-4">
                  <div className="w-11 h-11 bg-gradient-to-br from-accent/15 to-accent/5 rounded-xl flex items-center justify-center border border-accent/10">
                    <span className="text-lg">🎵</span>
                  </div>
                  <div className="flex-1 min-w-0">
                    <h3 className="text-text-primary font-semibold truncate">{fav.name}</h3>
                    <p className="text-text-muted text-xs">📍 {fav.city}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <span className="text-warning text-xs">★</span>
                    <span className="text-text-primary text-sm font-medium">{fav.average_rating}</span>
                    <span className="text-text-muted text-xs">({fav.total_reviews})</span>
                  </div>
                  <div className="flex gap-2">
                    <a
                      href={`http://localhost:5173/studios/${fav.slug}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="btn-gold text-xs py-1 px-3"
                    >View</a>
                    <button
                      onClick={() => handleRemove(fav.id)}
                      className="px-3 py-1 text-xs font-medium bg-danger/10 text-danger border border-danger/20 rounded-lg hover:bg-danger/15 transition-colors"
                    >Remove</button>
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
