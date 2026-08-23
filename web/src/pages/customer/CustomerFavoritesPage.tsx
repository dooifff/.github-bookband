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

  useEffect(() => {
    fetchFavorites()
  }, [])

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
        <div>
          <h1 className="text-2xl font-bold text-text-primary">My Favorites</h1>
          <p className="text-text-secondary">Studios you've saved</p>
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="text-accent animate-pulse">Loading favorites...</div>
          </div>
        ) : favorites.length === 0 ? (
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <span className="text-4xl mb-4 block">❤️</span>
            <p className="text-text-muted text-lg">No favorites yet</p>
            <a href="/customer/studios" className="text-accent hover:underline mt-2 inline-block">
              Browse studios to add favorites
            </a>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {favorites.map((fav) => (
              <div key={fav.id} className="bg-surface border border-border rounded-xl p-5">
                <div className="flex items-center gap-3 mb-3">
                  <div className="w-12 h-12 bg-accent/10 rounded-full flex items-center justify-center">
                    <span className="text-xl">🎵</span>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-text-primary font-semibold">{fav.name}</h3>
                    <p className="text-text-muted text-sm">📍 {fav.city}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1">
                    <span className="text-warning">⭐</span>
                    <span className="text-text-primary text-sm">{fav.average_rating}</span>
                    <span className="text-text-muted text-sm">({fav.total_reviews})</span>
                  </div>
                  <div className="flex gap-2">
                    <a
                      href={`http://localhost:5173/studios/${fav.slug}`}
                      target="_blank"
                      className="px-3 py-1 bg-accent text-primary text-sm rounded hover:bg-accent-hover transition-colors"
                    >
                      View
                    </a>
                    <button
                      onClick={() => handleRemove(fav.id)}
                      className="px-3 py-1 bg-red-500/10 text-red-500 text-sm rounded hover:bg-red-500/20 transition-colors"
                    >
                      Remove
                    </button>
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
