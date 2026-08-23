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

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalCount, setTotalCount] = useState(0)

  useEffect(() => {
    fetchBookings()
  }, [page, statusFilter])

  const fetchBookings = async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (statusFilter) params.append('status', statusFilter)
      params.append('page', page.toString())

      const response = await api.get(`/admin/bookings?${params.toString()}`)
      // Backend returns: { success, message, data: [...], meta: { current_page, last_page, per_page, total } }
      setBookings(response.data.data || [])
      setTotalPages(response.data.meta?.last_page || 1)
      setTotalCount(response.data.meta?.total || 0)
    } catch (err: any) {
      console.error('Failed to fetch bookings:', err)
      setError(err.response?.data?.message || 'Failed to load bookings')
      setBookings([])
    } finally {
      setLoading(false)
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
      refunded: 'bg-purple-500/20 text-purple-500',
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

  if (error && bookings.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Bookings</h1>
            <p className="text-text-secondary">View and manage all bookings</p>
          </div>
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <p className="text-error mb-4">{error}</p>
            <button
              onClick={fetchBookings}
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Bookings</h1>
            <p className="text-text-secondary">View and manage all bookings ({totalCount} total)</p>
          </div>
        </div>

        {/* Filters */}
        <div className="bg-surface border border-border rounded-xl p-4">
          <div className="flex flex-wrap gap-4">
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
            >
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="confirmed">Confirmed</option>
              <option value="ongoing">Ongoing</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
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
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Studio</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Date & Time</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Amount</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-text-muted">
                      <div className="animate-pulse">Loading bookings...</div>
                    </td>
                  </tr>
                ) : bookings.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="px-6 py-12 text-center text-text-muted">
                      <p className="text-lg mb-2">No bookings found</p>
                      <p className="text-sm">Try adjusting your filters</p>
                    </td>
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
