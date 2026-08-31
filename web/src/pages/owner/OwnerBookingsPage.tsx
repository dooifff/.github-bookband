import { useState, useEffect, useCallback } from 'react'
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

  const fetchStudios = useCallback(async () => {
    try {
      const response = await api.get('/owner/studios')
      setStudios(response.data.data.data || [])
    } catch (error) {
      console.error('Failed to fetch studios:', error)
    }
  }, [])

  const fetchBookings = useCallback(async () => {
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
  }, [page, statusFilter, studioFilter])

  useEffect(() => { fetchStudios() }, [fetchStudios])
  useEffect(() => { fetchBookings() }, [fetchBookings])

  const handleConfirmBooking = async (bookingId: number) => {
    try { await api.post(`/owner/bookings/${bookingId}/confirm`); fetchBookings() } catch (error) { console.error('Failed to confirm booking:', error) }
  }

  const handleCompleteBooking = async (bookingId: number) => {
    try { await api.post(`/owner/bookings/${bookingId}/complete`); fetchBookings() } catch (error) { console.error('Failed to complete booking:', error) }
  }

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-warning/10 text-warning border border-warning/20',
      awaiting_payment: 'bg-amber-500/10 text-amber-400 border border-amber-500/20',
      paid: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
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
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Pemesanan</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola pemesanan studio Anda</p>
        </div>

        {/* Filters */}
        <div className="glass-subtle rounded-xl p-4 animate-fade-in-up stagger-1">
          <div className="flex flex-wrap gap-3">
            <select
              value={statusFilter}
              onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }}
              className="select-luxury text-sm"
            >
              <option value="">Semua Status</option>
              <option value="pending">Menunggu</option>
              <option value="confirmed">Dikonfirmasi</option>
              <option value="ongoing">Berlangsung</option>
              <option value="completed">Selesai</option>
              <option value="cancelled">Dibatalkan</option>
            </select>
            <select
              value={studioFilter}
              onChange={(e) => { setStudioFilter(e.target.value); setPage(1) }}
              className="select-luxury text-sm"
            >
              <option value="">Semua Studio</option>
              {studios.map((studio) => (
                <option key={studio.id} value={studio.id}>{studio.name}</option>
              ))}
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
                  <th>Studio & Room</th>
                  <th>Date & Time</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {loading ? (
                  <tr><td colSpan={7} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-sm">Memuat pemesanan...</p>
                    </div>
                  </td></tr>
                ) : bookings.length === 0 ? (
                  <tr><td colSpan={7} className="px-6 py-16 text-center">
                    <p className="text-text-muted text-sm">Tidak ada pemesanan ditemukan</p>
                  </td></tr>
                ) : (
                  bookings.map((booking) => (
                    <tr key={booking.id}>
                      <td>
                        <span className="font-mono text-accent text-xs font-medium">{booking.booking_code}</span>
                      </td>
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
                      <td>
                        <span className={`badge ${getStatusBadge(booking.status)}`}>{booking.status}</span>
                      </td>
                      <td>
                        <div className="flex items-center gap-2">
                          {booking.status === 'pending' && (
                            <button onClick={() => handleConfirmBooking(booking.id)} className="btn-glass text-xs py-1.5 px-3">Konfirmasi</button>
                          )}
                          {booking.status === 'confirmed' && (
                            <button onClick={() => handleCompleteBooking(booking.id)} className="btn-gold text-xs py-1.5 px-3">Selesai</button>
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
            <div className="px-6 py-4 border-t border-border/40 flex items-center justify-between">
              <p className="text-text-muted text-xs">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Sebelumnya</button>
                <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Selanjutnya</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  )
}
