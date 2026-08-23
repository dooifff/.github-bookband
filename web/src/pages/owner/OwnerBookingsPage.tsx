import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Booking {
  id: number
  booking_code: string
  status: string
  booking_date: string
  start_time: string
  end_time: string
  total_amount: number
  user: { name: string; email: string }
  studio: { name: string }
  room: { name: string }
  created_at: string
}

export default function OwnerBookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('')
  const [studioFilter, setStudioFilter] = useState('')
  const [studios, setStudios] = useState<any[]>([])
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  useEffect(() => {
    fetchStudios()
  }, [])

  useEffect(() => {
    fetchBookings()
  }, [page, statusFilter, studioFilter])

  const fetchStudios = async () => {
    try {
      const response = await api.get('/owner/studios')
      setStudios(response.data.data.data || [])
    } catch (error) {
      console.error('Failed to fetch studios:', error)
    }
  }

  const fetchBookings = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (statusFilter) params.append('status', statusFilter)
      if (studioFilter) params.append('studio_id', studioFilter)
      params.append('page', page.toString())
      
      const response = await api.get(`/owner/bookings?${params.toString()}`)
      setBookings(response.data.data.data || [])
      setTotalPages(response.data.data.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch bookings:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleConfirmBooking = async (bookingId: number) => {
    try {
      await api.post(`/owner/bookings/${bookingId}/confirm`)
      fetchBookings()
    } catch (error) {
      console.error('Failed to confirm booking:', error)
    }
  }

  const handleCompleteBooking = async (bookingId: number) => {
    try {
      await api.post(`/owner/bookings/${bookingId}/complete`)
      fetchBookings()
    } catch (error) {
      console.error('Failed to complete booking:', error)
    }
  }

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-warning/20 text-warning',
      awaiting_payment: 'bg-amber-500/20 text-amber-500',
      paid: 'bg-blue-500/20 text-blue-500',
      confirmed: 'bg-success/20 text-success',
      ongoing: 'bg-accent/20 text-accent',
      completed: 'bg-green-500/20 text-green-500',
      cancelled: 'bg-error/20 text-error',
    }
    return styles[status] || 'bg-text-muted/20 text-text-muted'
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount)
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Bookings</h1>
          <p className="text-text-secondary">Manage your studio bookings</p>
        </div>

        {/* Filters */}
        <div className="bg-surface border border-border rounded-xl p-4">
          <div className="flex flex-wrap gap-4">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
            >
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="confirmed">Confirmed</option>
              <option value="ongoing">Ongoing</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
            <select
              value={studioFilter}
              onChange={(e) => setStudioFilter(e.target.value)}
              className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
            >
              <option value="">All Studios</option>
              {studios.map((studio) => (
                <option key={studio.id} value={studio.id}>{studio.name}</option>
              ))}
            </select>
          </div>
        </div>

        {/* Bookings Table */}
        <div className="bg-surface border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-surface-light">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Code</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Customer</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Studio & Room</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Date & Time</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-text-muted">Loading...</td>
                  </tr>
                ) : bookings.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-6 py-12 text-center text-text-muted">No bookings found</td>
                  </tr>
                ) : (
                  bookings.map((booking) => (
                    <tr key={booking.id} className="hover:bg-surface-light/50 transition-colors">
                      <td className="px-6 py-4">
                        <span className="font-mono text-accent">{booking.booking_code}</span>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-text-primary">{booking.user?.name}</p>
                        <p className="text-text-muted text-sm">{booking.user?.email}</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-text-primary">{booking.studio?.name}</p>
                        <p className="text-text-muted text-sm">{booking.room?.name}</p>
                      </td>
                      <td className="px-6 py-4">
                        <p className="text-text-primary">{booking.booking_date}</p>
                        <p className="text-text-muted text-sm">{booking.start_time} - {booking.end_time}</p>
                      </td>
                      <td className="px-6 py-4 text-text-primary font-medium">
                        {formatCurrency(booking.total_amount)}
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 text-xs rounded ${getStatusBadge(booking.status)}`}>
                          {booking.status}
                        </span>
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          {booking.status === 'pending' && (
                            <button
                              onClick={() => handleConfirmBooking(booking.id)}
                              className="px-2 py-1 text-xs bg-success/10 text-success rounded hover:bg-success/20 transition-colors"
                            >
                              Confirm
                            </button>
                          )}
                          {booking.status === 'confirmed' && (
                            <button
                              onClick={() => handleCompleteBooking(booking.id)}
                              className="px-2 py-1 text-xs bg-success/10 text-success rounded hover:bg-success/20 transition-colors"
                            >
                              Complete
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
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50"
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
