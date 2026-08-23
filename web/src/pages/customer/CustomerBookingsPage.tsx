import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Booking {
  id: number
  booking_code: string
  studio: { name: string; city: string }
  room: { name: string }
  date: string
  start_time: string
  end_time: string
  duration_hours: number
  status: string
  pricing: { total: string; formatted_total: string }
  notes: string
}

export default function CustomerBookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('')

  useEffect(() => {
    fetchBookings()
  }, [filter])

  const fetchBookings = async () => {
    try {
      setLoading(true)
      const params = filter ? `?status=${filter}` : ''
      const response = await api.get(`/bookings${params}`)
      setBookings(response.data.data || [])
    } catch (error) {
      console.error('Failed to fetch bookings:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleCancel = async (id: number) => {
    if (!confirm('Are you sure you want to cancel this booking?')) return
    try {
      await api.post(`/bookings/${id}/cancel`, { reason: 'Cancelled by customer' })
      fetchBookings()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Failed to cancel booking')
    }
  }

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      pending: 'bg-warning/20 text-warning',
      awaiting_payment: 'bg-amber-500/20 text-amber-500',
      confirmed: 'bg-success/20 text-success',
      ongoing: 'bg-blue-500/20 text-blue-500',
      completed: 'bg-green-500/20 text-green-500',
      cancelled: 'bg-red-500/20 text-red-500',
    }
    return colors[status] || 'bg-text-muted/20 text-text-muted'
  }

  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = {
      pending: 'Pending',
      awaiting_payment: 'Awaiting Payment',
      confirmed: 'Confirmed',
      ongoing: 'Ongoing',
      completed: 'Completed',
      cancelled: 'Cancelled',
    }
    return labels[status] || status
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-bold text-text-primary">My Bookings</h1>
          <p className="text-text-secondary">View and manage your studio bookings</p>
        </div>

        {/* Filter */}
        <div className="flex gap-2 flex-wrap">
          {['', 'pending', 'confirmed', 'completed', 'cancelled'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                filter === f
                  ? 'bg-accent text-primary'
                  : 'bg-surface border border-border text-text-secondary hover:text-text-primary'
              }`}
            >
              {f ? getStatusLabel(f) : 'All'}
            </button>
          ))}
        </div>

        {/* Bookings List */}
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="text-accent animate-pulse">Loading bookings...</div>
          </div>
        ) : bookings.length === 0 ? (
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <span className="text-4xl mb-4 block">📅</span>
            <p className="text-text-muted text-lg">No bookings found</p>
            <a href="/customer/studios" className="text-accent hover:underline mt-2 inline-block">
              Browse studios to make a booking
            </a>
          </div>
        ) : (
          <div className="space-y-4">
            {bookings.map((booking) => (
              <div key={booking.id} className="bg-surface border border-border rounded-xl p-6">
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-accent font-mono font-bold">{booking.booking_code}</span>
                      <span className={`px-2 py-1 text-xs rounded ${getStatusColor(booking.status)}`}>
                        {getStatusLabel(booking.status)}
                      </span>
                    </div>
                    <h3 className="text-text-primary font-semibold">{booking.studio?.name}</h3>
                    <p className="text-text-secondary text-sm">{booking.room?.name}</p>
                    <div className="flex items-center gap-4 mt-2 text-sm text-text-muted">
                      <span>📅 {new Date(booking.date).toLocaleDateString('id-ID')}</span>
                      <span>🕐 {booking.start_time} - {booking.end_time}</span>
                      <span>⏱️ {booking.duration_hours}h</span>
                    </div>
                    {booking.notes && (
                      <p className="text-text-muted text-sm mt-2 italic">"{booking.notes}"</p>
                    )}
                  </div>
                  <div className="text-right">
                    <p className="text-xl font-bold text-accent">{booking.pricing?.formatted_total}</p>
                    {['pending', 'awaiting_payment'].includes(booking.status) && (
                      <button
                        onClick={() => handleCancel(booking.id)}
                        className="mt-2 px-3 py-1 text-xs bg-red-500/10 text-red-500 rounded hover:bg-red-500/20 transition-colors"
                      >
                        Cancel
                      </button>
                    )}
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
