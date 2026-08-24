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

  useEffect(() => { fetchBookings() }, [filter])

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

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-warning/10 text-warning border border-warning/20',
      awaiting_payment: 'bg-amber-500/10 text-amber-400 border border-amber-500/20',
      confirmed: 'bg-success/10 text-success border border-success/20',
      ongoing: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
      completed: 'bg-green-500/10 text-green-400 border border-green-500/20',
      cancelled: 'bg-danger/10 text-danger border border-danger/20',
    }
    return styles[status] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = {
      pending: 'Pending', awaiting_payment: 'Awaiting Payment', confirmed: 'Confirmed',
      ongoing: 'Ongoing', completed: 'Completed', cancelled: 'Cancelled',
    }
    return labels[status] || status
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">My Bookings</h1>
          <p className="text-text-secondary mt-1 text-sm">View and manage your studio bookings</p>
        </div>

        {/* Filters */}
        <div className="flex gap-2 flex-wrap animate-fade-in-up stagger-1">
          {['', 'pending', 'confirmed', 'completed', 'cancelled'].map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-4 py-2 rounded-xl text-xs font-medium transition-all duration-200 ${
                filter === f
                  ? 'bg-accent text-primary shadow-sm shadow-accent/20'
                  : 'bg-surface-light border border-border text-text-secondary hover:text-text-primary hover:border-border-light'
              }`}
            >
              {f ? getStatusLabel(f) : 'All'}
            </button>
          ))}
        </div>

        {/* Bookings */}
        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Loading bookings...</p>
            </div>
          </div>
        ) : bookings.length === 0 ? (
          <div className="card-luxury p-16 text-center animate-fade-in">
            <span className="text-4xl mb-4 block">📅</span>
            <p className="text-text-muted text-lg">No bookings found</p>
            <a href="/customer/studios" className="text-accent text-sm hover:text-accent-hover mt-2 inline-block transition-colors">
              Browse studios to make a booking →
            </a>
          </div>
        ) : (
          <div className="space-y-4">
            {bookings.map((booking, i) => (
              <div key={booking.id} className={`card-luxury p-6 animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-3">
                      <span className="font-mono text-accent text-xs font-semibold">{booking.booking_code}</span>
                      <span className={`badge ${getStatusBadge(booking.status)}`}>
                        {getStatusLabel(booking.status)}
                      </span>
                    </div>
                    <h3 className="text-text-primary font-semibold">{booking.studio?.name}</h3>
                    <p className="text-text-secondary text-sm">{booking.room?.name}</p>
                    <div className="flex items-center gap-4 mt-3 text-xs text-text-muted">
                      <span>📅 {new Date(booking.date).toLocaleDateString('id-ID')}</span>
                      <span>🕐 {booking.start_time} – {booking.end_time}</span>
                      <span>⏱️ {booking.duration_hours}h</span>
                    </div>
                    {booking.notes && (
                      <p className="text-text-muted text-xs mt-3 italic">"{booking.notes}"</p>
                    )}
                  </div>
                  <div className="text-right ml-4">
                    <p className="text-xl font-bold gold-text-static">{booking.pricing?.formatted_total}</p>
                    {['pending', 'awaiting_payment'].includes(booking.status) && (
                      <button
                        onClick={() => handleCancel(booking.id)}
                        className="mt-3 px-3 py-1.5 text-xs font-medium bg-danger/10 text-danger border border-danger/20 rounded-lg hover:bg-danger/15 transition-colors"
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
