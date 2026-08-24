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
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  useEffect(() => { fetchBookings() }, [page, statusFilter])

  const fetchBookings = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (statusFilter) params.append('status', statusFilter)
      params.append('page', page.toString())
      const response = await api.get(`/admin/bookings?${params.toString()}`)
      setBookings(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch bookings:', error)
    } finally {
      setLoading(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-warning/10 text-warning border border-warning/20',
      confirmed: 'bg-success/10 text-success border border-success/20',
      ongoing: 'bg-accent/10 text-accent border border-accent/20',
      completed: 'bg-green-500/10 text-green-400 border border-green-500/20',
      cancelled: 'bg-danger/10 text-danger border border-danger/20',
    }
    return styles[status] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Bookings</h1>
          <p className="text-text-secondary mt-1 text-sm">Manage all platform bookings</p>
        </div>

        {/* Filters */}
        <div className="glass-subtle rounded-xl p-4 animate-fade-in-up stagger-1">
          <div className="flex flex-wrap gap-3">
            <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }} className="select-luxury text-sm">
              <option value="">All Status</option>
              <option value="pending">Pending</option>
              <option value="confirmed">Confirmed</option>
              <option value="ongoing">Ongoing</option>
              <option value="completed">Completed</option>
              <option value="cancelled">Cancelled</option>
            </select>
          </div>
        </div>

        {/* Table */}
        <div className="card-luxury overflow-hidden animate-fade-in-up stagger-2">
          <div className="overflow-x-auto">
            <table className="w-full table-luxury">
              <thead>
                <tr>
                  <th>Code</th>
                  <th>Customer</th>
                  <th>Studio</th>
                  <th>Date</th>
                  <th>Amount</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {loading ? (
                  <tr><td colSpan={6} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-sm">Loading bookings...</p>
                    </div>
                  </td></tr>
                ) : bookings.length === 0 ? (
                  <tr><td colSpan={6} className="px-6 py-16 text-center text-text-muted text-sm">No bookings found</td></tr>
                ) : (
                  bookings.map((booking) => (
                    <tr key={booking.id}>
                      <td><span className="font-mono text-accent text-xs font-medium">{booking.booking_code}</span></td>
                      <td>
                        <p className="text-text-primary text-sm font-medium">{booking.user?.name}</p>
                        <p className="text-text-muted text-xs">{booking.user?.email}</p>
                      </td>
                      <td>
                        <p className="text-text-primary text-sm">{booking.studio?.name}</p>
                        <p className="text-text-muted text-xs">{booking.room?.name}</p>
                      </td>
                      <td>
                        <p className="text-text-primary text-sm">{booking.booking_date}</p>
                        <p className="text-text-muted text-xs">{booking.start_time} – {booking.end_time}</p>
                      </td>
                      <td className="text-text-primary text-sm font-medium">{formatCurrency(booking.total_amount)}</td>
                      <td><span className={`badge ${getStatusBadge(booking.status)}`}>{booking.status}</span></td>
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
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Previous</button>
                <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Next</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  )
}
