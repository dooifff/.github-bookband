import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Booking {
  id: number
  booking_code: string
  status: string
  date: string
  start_time: string
  end_time: string
  duration_hours: number
  total: number
  subtotal: number
  discount: number
  notes: string
  cancel_reason: string
  user: { id: number; name: string; email: string }
  studio: { id: number; name: string }
  room: { id: number; name: string }
  payment: { id: number; amount: number; status: string; method: string; paid_at: string } | null
  created_at: string
}

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [loading, setLoading] = useState(true)
  const [statusFilter, setStatusFilter] = useState('')
  const [search, setSearch] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  // Detail modal
  const [selectedBooking, setSelectedBooking] = useState<Booking | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Cancel modal
  const [cancellingBooking, setCancellingBooking] = useState<Booking | null>(null)
  const [cancelReason, setCancelReason] = useState('Dibatalkan oleh admin')

  const [actionLoading, setActionLoading] = useState(false)

  const fetchBookings = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (statusFilter) params.append('status', statusFilter)
      if (search) params.append('search', search)
      params.append('page', page.toString())
      const response = await api.get(`/admin/bookings?${params.toString()}`)
      setBookings(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch bookings:', error)
    } finally {
      setLoading(false)
    }
  }, [page, statusFilter, search])

  useEffect(() => { fetchBookings() }, [fetchBookings])

  // Fetch booking detail
  const fetchBookingDetail = async (bookingId: number) => {
    setDetailLoading(true)
    try {
      const response = await api.get(`/admin/bookings/${bookingId}`)
      setSelectedBooking(response.data.data)
    } catch (error) {
      console.error('Failed to fetch booking detail:', error)
    } finally {
      setDetailLoading(false)
    }
  }

  // Confirm booking
  const confirmBooking = async (booking: Booking) => {
    if (!confirm(`Konfirmasi booking "${booking.booking_code}"?`)) return
    setActionLoading(true)
    try {
      await api.post(`/admin/bookings/${booking.id}/confirm`)
      await fetchBookings()
      if (selectedBooking?.id === booking.id) {
        fetchBookingDetail(booking.id)
      }
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal mengkonfirmasi booking')
    } finally {
      setActionLoading(false)
    }
  }

  // Cancel booking
  const cancelBooking = async () => {
    if (!cancellingBooking) return
    setActionLoading(true)
    try {
      await api.post(`/admin/bookings/${cancellingBooking.id}/cancel`, { reason: cancelReason })
      setCancellingBooking(null)
      setCancelReason('Dibatalkan oleh admin')
      await fetchBookings()
      if (selectedBooking?.id === cancellingBooking.id) {
        fetchBookingDetail(cancellingBooking.id)
      }
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal membatalkan booking')
    } finally {
      setActionLoading(false)
    }
  }

  const getStatusBadge = (status: string) => {
    const styles: Record<string, string> = {
      pending: 'bg-warning/10 text-warning border border-warning/20',
      awaiting_payment: 'bg-orange-500/10 text-orange-400 border border-orange-500/20',
      confirmed: 'bg-success/10 text-success border border-success/20',
      paid: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
      ongoing: 'bg-accent/10 text-accent border border-accent/20',
      completed: 'bg-green-500/10 text-green-400 border border-green-500/20',
      cancelled: 'bg-danger/10 text-danger border border-danger/20',
    }
    return styles[status] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = {
      pending: 'Menunggu',
      awaiting_payment: 'Menunggu Pembayaran',
      confirmed: 'Dikonfirmasi',
      paid: 'Dibayar',
      ongoing: 'Berlangsung',
      completed: 'Selesai',
      cancelled: 'Dibatalkan',
    }
    return labels[status] || status
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const canConfirm = (status: string) => ['pending', 'awaiting_payment'].includes(status)
  const canCancel = (status: string) => ['pending', 'awaiting_payment', 'paid'].includes(status)

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-2xl font-bold text-text-primary tracking-tight">Pemesanan</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola semua pemesanan platform</p>
        </div>

        {/* Filters */}
        <div className="flex gap-3 flex-wrap animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Cari kode booking / nama..."
            className="input-luxury text-sm flex-1 min-w-[200px] max-w-xs"
          />
          <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1) }} className="select-luxury text-sm">
            <option value="">Semua Status</option>
            <option value="pending">Menunggu</option>
            <option value="awaiting_payment">Menunggu Pembayaran</option>
            <option value="confirmed">Dikonfirmasi</option>
            <option value="completed">Selesai</option>
            <option value="cancelled">Dibatalkan</option>
          </select>
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
                  <th>Tanggal</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Aksi</th>
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
                  <tr><td colSpan={7} className="px-6 py-16 text-center text-text-muted text-sm">Tidak ada pemesanan ditemukan</td></tr>
                ) : (
                  bookings.map((booking) => (
                    <tr key={booking.id}>
                      <td>
                        <button onClick={() => fetchBookingDetail(booking.id)} className="font-mono text-accent text-xs font-medium hover:text-accent-hover transition-colors">
                          {booking.booking_code}
                        </button>
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
                        <p className="text-text-primary text-sm">{booking.date}</p>
                        <p className="text-text-muted text-xs">{booking.start_time} – {booking.end_time}</p>
                      </td>
                      <td className="text-text-primary text-sm font-medium">{formatCurrency(booking.total)}</td>
                      <td>
                        <span className={`badge ${getStatusBadge(booking.status)}`}>{getStatusLabel(booking.status)}</span>
                      </td>
                      <td>
                        <div className="flex items-center gap-1.5">
                          <button
                            onClick={() => fetchBookingDetail(booking.id)}
                            className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-surface-lighter/60 text-text-secondary hover:text-text-primary hover:bg-surface-light transition-all"
                          >
                            Detail
                          </button>
                          {canConfirm(booking.status) && (
                            <button
                              onClick={() => confirmBooking(booking)}
                              disabled={actionLoading}
                              className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-success/10 text-success hover:bg-success/20 transition-all disabled:opacity-40"
                            >
                              ✓ Konfirmasi
                            </button>
                          )}
                          {canCancel(booking.status) && (
                            <button
                              onClick={() => setCancellingBooking(booking)}
                              disabled={actionLoading}
                              className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-danger/10 text-danger hover:bg-danger/20 transition-all disabled:opacity-40"
                            >
                              ✕ Batal
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

      {/* ─── Booking Detail Modal ─── */}
      {(selectedBooking || detailLoading) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedBooking(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-lg max-h-[85vh] overflow-y-auto glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Detail Pemesanan</h2>
              <button onClick={() => setSelectedBooking(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            {detailLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              </div>
            ) : selectedBooking && (
              <>
                {/* Code & Status */}
                <div className="flex items-center justify-between p-4 bg-surface-light/50 rounded-xl">
                  <div>
                    <p className="font-mono text-accent text-lg font-bold">{selectedBooking.booking_code}</p>
                    <p className="text-text-muted text-xs mt-0.5">Dibuat: {new Date(selectedBooking.created_at).toLocaleString('id-ID')}</p>
                  </div>
                  <span className={`badge ${getStatusBadge(selectedBooking.status)}`}>{getStatusLabel(selectedBooking.status)}</span>
                </div>

                {/* Customer & Studio */}
                <div className="grid grid-cols-2 gap-3">
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs mb-1">Customer</p>
                    <p className="text-text-primary text-sm font-medium">{selectedBooking.user?.name}</p>
                    <p className="text-text-muted text-xs">{selectedBooking.user?.email}</p>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs mb-1">Studio</p>
                    <p className="text-text-primary text-sm font-medium">{selectedBooking.studio?.name}</p>
                    <p className="text-text-muted text-xs">{selectedBooking.room?.name}</p>
                  </div>
                </div>

                {/* Schedule */}
                <div className="bg-surface-light/50 rounded-xl p-4">
                  <p className="text-text-muted text-xs mb-2">Jadwal</p>
                  <div className="grid grid-cols-3 gap-3">
                    <div>
                      <p className="text-text-muted text-[0.65rem]">Tanggal</p>
                      <p className="text-text-primary text-sm font-medium">{selectedBooking.date}</p>
                    </div>
                    <div>
                      <p className="text-text-muted text-[0.65rem]">Waktu</p>
                      <p className="text-text-primary text-sm font-medium">{selectedBooking.start_time} – {selectedBooking.end_time}</p>
                    </div>
                    <div>
                      <p className="text-text-muted text-[0.65rem]">Durasi</p>
                      <p className="text-text-primary text-sm font-medium">{selectedBooking.duration_hours} jam</p>
                    </div>
                  </div>
                </div>

                {/* Price Breakdown */}
                <div className="bg-surface-light/50 rounded-xl p-4">
                  <p className="text-text-muted text-xs mb-2">Rincian Harga</p>
                  <div className="space-y-1.5">
                    <div className="flex justify-between text-sm">
                      <span className="text-text-secondary">Subtotal</span>
                      <span className="text-text-primary">{formatCurrency(selectedBooking.subtotal)}</span>
                    </div>
                    {selectedBooking.discount > 0 && (
                      <div className="flex justify-between text-sm">
                        <span className="text-success">Diskon</span>
                        <span className="text-success">-{formatCurrency(selectedBooking.discount)}</span>
                      </div>
                    )}
                    <div className="border-t border-border/40 pt-1.5 flex justify-between text-sm font-semibold">
                      <span className="text-text-primary">Total</span>
                      <span className="text-accent">{formatCurrency(selectedBooking.total)}</span>
                    </div>
                  </div>
                </div>

                {/* Payment */}
                {selectedBooking.payment && (
                  <div className="bg-surface-light/50 rounded-xl p-4">
                    <p className="text-text-muted text-xs mb-2">Pembayaran</p>
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="text-text-primary text-sm font-medium">{formatCurrency(selectedBooking.payment.amount)}</p>
                        <p className="text-text-muted text-xs">Metode: {selectedBooking.payment.method || '-'}</p>
                      </div>
                      <span className={`badge text-[0.6rem] ${selectedBooking.payment.status === 'paid' ? 'bg-success/10 text-success' : 'bg-warning/10 text-warning'}`}>
                        {selectedBooking.payment.status}
                      </span>
                    </div>
                  </div>
                )}

                {/* Cancel Reason */}
                {selectedBooking.cancel_reason && (
                  <div className="bg-danger/5 border border-danger/10 rounded-xl p-3">
                    <p className="text-danger text-xs font-medium mb-0.5">Alasan Pembatalan</p>
                    <p className="text-text-secondary text-sm">{selectedBooking.cancel_reason}</p>
                  </div>
                )}

                {/* Notes */}
                {selectedBooking.notes && (
                  <div className="bg-surface-light/50 rounded-xl p-3">
                    <p className="text-text-muted text-xs mb-0.5">Catatan</p>
                    <p className="text-text-secondary text-sm">{selectedBooking.notes}</p>
                  </div>
                )}

                {/* Action Buttons */}
                {(canConfirm(selectedBooking.status) || canCancel(selectedBooking.status)) && (
                  <div className="flex gap-2 pt-2">
                    {canConfirm(selectedBooking.status) && (
                      <button
                        onClick={() => { confirmBooking(selectedBooking); setSelectedBooking(null) }}
                        disabled={actionLoading}
                        className="flex-1 btn-gold py-2.5 text-sm font-medium disabled:opacity-40"
                      >
                        ✓ Konfirmasi Booking
                      </button>
                    )}
                    {canCancel(selectedBooking.status) && (
                      <button
                        onClick={() => { setCancellingBooking(selectedBooking); setSelectedBooking(null) }}
                        disabled={actionLoading}
                        className="flex-1 py-2.5 text-sm font-medium rounded-xl bg-danger/10 text-danger hover:bg-danger/20 border border-danger/20 transition-all disabled:opacity-40"
                      >
                        ✕ Batalkan Booking
                      </button>
                    )}
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {/* ─── Cancel Confirmation Modal ─── */}
      {cancellingBooking && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setCancellingBooking(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-sm glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Batalkan Booking</h2>
              <button onClick={() => setCancellingBooking(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            <p className="text-text-secondary text-sm">
              Booking <span className="font-mono text-accent font-medium">{cancellingBooking.booking_code}</span> akan dibatalkan.
            </p>

            <div>
              <label className="text-text-secondary text-xs font-medium block mb-1.5">Alasan Pembatalan</label>
              <textarea
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                className="input-luxury w-full text-sm h-20 resize-none"
                placeholder="Masukkan alasan pembatalan..."
              />
            </div>

            <div className="flex gap-2 justify-end">
              <button onClick={() => setCancellingBooking(null)} className="btn-glass text-sm py-2 px-4">Batal</button>
              <button
                onClick={cancelBooking}
                disabled={actionLoading || !cancelReason.trim()}
                className="py-2 px-4 text-sm font-medium rounded-xl bg-danger text-white hover:bg-danger/90 transition-all disabled:opacity-40"
              >
                {actionLoading ? 'Membatalkan...' : 'Batalkan Booking'}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
