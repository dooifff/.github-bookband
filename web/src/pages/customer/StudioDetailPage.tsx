import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Room {
  id: number
  name: string
  description: string
  price_per_hour: number
  capacity: number
  is_active: boolean
  equipment: { name: string }[]
}

interface OpeningHour {
  day: string
  open_time: string
  close_time: string
  is_closed: boolean
}

interface Facility {
  id: number
  name: string
  description: string | null
  icon: string | null
  image: string | null
}

interface Studio {
  id: number
  name: string
  slug: string
  description: string
  address: string
  city: string
  province: string
  phone: string
  email: string
  average_rating: number
  total_reviews: number
  is_verified: boolean
  owner: { name: string; avatar: string | null }
  rooms: Room[]
  opening_hours: OpeningHour[]
  equipment: { name: string; category: string }[]
  facilities: Facility[]
}

interface Review {
  id: number
  user: { id: number; name: string }
  rating: number
  comment: string
  created_at: string
}

interface ReviewSummary {
  average_rating: number
  total_reviews: number
  rating_distribution: Record<number, number>
}

interface BookingOption {
  id: number
  booking_code: string
  date: string
}

export default function StudioDetailPage() {
  const { slug } = useParams<{ slug: string }>()
  const navigate = useNavigate()
  const [studio, setStudio] = useState<Studio | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Booking form state
  const [selectedRoom, setSelectedRoom] = useState<number | null>(null)
  const [date, setDate] = useState('')
  const [startTime, setStartTime] = useState('')
  const [endTime, setEndTime] = useState('')
  const [notes, setNotes] = useState('')
  const [promoCode, setPromoCode] = useState('')
  const [bookingLoading, setBookingLoading] = useState(false)
  const [bookingSuccess, setBookingSuccess] = useState(false)
  const [bookingError, setBookingError] = useState('')
  const [estimatedPrice, setEstimatedPrice] = useState<number | null>(null)

  // Reviews & rating state
  const [reviews, setReviews] = useState<Review[]>([])
  const [reviewSummary, setReviewSummary] = useState<ReviewSummary | null>(null)
  const [reviewsLoading, setReviewsLoading] = useState(true)
  const [completedBookings, setCompletedBookings] = useState<BookingOption[]>([])
  const [reviewBookingId, setReviewBookingId] = useState<number | null>(null)
  const [reviewRating, setReviewRating] = useState(5)
  const [reviewComment, setReviewComment] = useState('')
  const [reviewSubmitting, setReviewSubmitting] = useState(false)
  const [reviewError, setReviewError] = useState('')
  const [reviewSuccess, setReviewSuccess] = useState(false)

  const fetchStudio = useCallback(async () => {
    try {
      const response = await api.get(`/studios/${slug}`)
      // Debug: log response asli biar mudah cek di console
      console.log('[StudioDetail] API response:', response.data)
      const studioData = response.data.data
      
      // Pastikan facilities selalu array (fallback kalau API ga mengirim)
      setStudio({
        ...studioData,
        facilities: Array.isArray(studioData?.facilities) ? studioData.facilities : [],
      })
    } catch (err: any) {
      console.error('Failed to fetch studio:', err)
      setError(err.response?.data?.message || 'Studio tidak ditemukan')
    } finally {
      setLoading(false)
    }
  }, [slug])

  useEffect(() => { fetchStudio() }, [fetchStudio])

  const fetchReviews = useCallback(async () => {
    try {
      const res = await api.get(`/studios/${slug}/reviews`)
      setReviews(res.data.data || [])
      setReviewSummary(res.data.summary || null)
    } catch (err) {
      console.error('Failed to fetch reviews:', err)
    } finally {
      setReviewsLoading(false)
    }
  }, [slug])

  useEffect(() => { fetchReviews() }, [fetchReviews])

  // Fetch user's completed bookings at this studio for the rating form
  useEffect(() => {
    if (!studio?.id) return
    const fetchCompletedBookings = async () => {
      try {
        const res = await api.get('/bookings?status=completed')
        const all: any[] = res.data.data || []
        const mine = all
          .filter((b) => b.studio?.id === studio.id)
          .map((b) => ({ id: b.id, booking_code: b.booking_code, date: b.date }))
        setCompletedBookings(mine)
        if (mine.length > 0) setReviewBookingId(mine[0].id)
      } catch (err) {
        console.error('Failed to fetch completed bookings:', err)
      }
    }
    fetchCompletedBookings()
  }, [studio?.id])

  // Calculate estimated price
  useEffect(() => {
    if (!selectedRoom || !startTime || !endTime || !studio) {
      setEstimatedPrice(null)
      return
    }
    const room = studio.rooms.find(r => r.id === selectedRoom)
    if (!room) return

    const [startH, startM] = startTime.split(':').map(Number)
    const [endH, endM] = endTime.split(':').map(Number)
    const hours = (endH + endM / 60) - (startH + startM / 60)
    if (hours > 0) {
      setEstimatedPrice(room.price_per_hour * hours)
    } else {
      setEstimatedPrice(null)
    }
  }, [selectedRoom, startTime, endTime, studio])

  const handleBooking = async (e: React.FormEvent) => {
    e.preventDefault()
    setBookingError('')

    if (!selectedRoom || !date || !startTime || !endTime) {
      setBookingError('Lengkapi semua field yang diperlukan')
      return
    }

    setBookingLoading(true)
    try {
      const payload: any = {
        studio_id: studio!.id,
        room_id: selectedRoom,
        date,
        start_time: startTime,
        end_time: endTime,
      }
      if (notes) payload.notes = notes
      if (promoCode) payload.promo_code = promoCode

      const response = await api.post('/bookings', payload)
      if (response.data.success) {
        setBookingSuccess(true)
        const bookingCode = response.data.data.booking_code
        setTimeout(() => {
          navigate(`/customer/payment/${bookingCode}`)
        }, 1500)
      }
    } catch (err: any) {
      setBookingError(err.response?.data?.message || 'Gagal membuat booking')
    } finally {
      setBookingLoading(false)
    }
  }

  const handleSubmitReview = async (e: React.FormEvent) => {
    e.preventDefault()
    setReviewError('')
    if (!reviewBookingId) {
      setReviewError('Pilih booking yang sudah selesai terlebih dahulu')
      return
    }
    setReviewSubmitting(true)
    try {
      await api.post('/reviews', {
        booking_id: reviewBookingId,
        rating: reviewRating,
        comment: reviewComment,
      })
      setReviewSuccess(true)
      setReviewComment('')
      setReviewBookingId(null)
      setCompletedBookings((prev) => prev.filter((b) => b.id !== reviewBookingId))
      fetchReviews()
      fetchStudio()
      setTimeout(() => setReviewSuccess(false), 4000)
    } catch (err: any) {
      setReviewError(err.response?.data?.message || 'Gagal mengirim rating')
    } finally {
      setReviewSubmitting(false)
    }
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const today = new Date().toISOString().split('T')[0]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat detail studio...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (error || !studio) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <span className="text-4xl block mb-4">🔍</span>
            <p className="text-danger mb-4">{error || 'Studio tidak ditemukan'}</p>
            <button onClick={() => navigate('/customer/studios')} className="btn-gold text-sm">Kembali ke Studio</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (bookingSuccess) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center animate-scale-in">
            <span className="text-5xl block mb-4">✅</span>
            <h2 className="text-xl font-bold text-text-primary mb-2">Booking Berhasil!</h2>
            <p className="text-text-muted text-sm">Anda akan dialihkan ke halaman pemesanan...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Back button */}
        <button onClick={() => navigate('/customer/studios')} className="flex items-center gap-2 text-text-secondary hover:text-text-primary transition-colors text-sm">
          ← Kembali ke Studio
        </button>

        {/* Studio Header */}
        <div className="card-luxury p-6 animate-fade-in-up">
          <div className="flex items-start justify-between">
            <div>
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-2xl font-bold text-text-primary">{studio.name}</h1>
                {studio.is_verified && (
                  <span className="px-2 py-0.5 bg-success/10 text-success border border-success/20 rounded-full text-xs font-medium">✓ Terverifikasi</span>
                )}
              </div>
              <p className="text-text-secondary text-sm">📍 {studio.address}, {studio.city}, {studio.province}</p>
              <div className="flex items-center gap-4 mt-2 text-sm text-text-muted">
                <span className="flex items-center gap-1"><span className="text-warning">★</span> {studio.average_rating} ({studio.total_reviews} ulasan)</span>
                {studio.phone && <span>📞 {studio.phone}</span>}
              </div>
            </div>
          </div>
          {studio.description && (
            <p className="text-text-secondary text-sm mt-4 leading-relaxed">{studio.description}</p>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left: Rooms & Info */}
          <div className="lg:col-span-2 space-y-6">
            {/* Rooms */}
            <div className="card-luxury p-6 animate-fade-in-up stagger-1">
              <h2 className="text-base font-semibold text-text-primary mb-4">🎵 Ruangan</h2>
              <div className="space-y-3">
                {studio.rooms.filter(r => r.is_active).map((room) => (
                  <div
                    key={room.id}
                    onClick={() => setSelectedRoom(room.id)}
                    className={`p-4 rounded-xl border cursor-pointer transition-all ${
                      selectedRoom === room.id
                        ? 'border-accent bg-accent/[0.05]'
                        : 'border-border/50 hover:border-border-light bg-surface-light/30'
                    }`}
                  >
                    <div className="flex items-start justify-between">
                      <div>
                        <h3 className="text-text-primary font-semibold text-sm">{room.name}</h3>
                        {room.description && <p className="text-text-muted text-xs mt-1">{room.description}</p>}
                        <div className="flex items-center gap-3 mt-2 text-xs text-text-muted">
                          <span>👥 Kapasitas: {room.capacity}</span>
                          <span>💰 {formatCurrency(room.price_per_hour)}/jam</span>
                        </div>
                        {room.equipment && room.equipment.length > 0 && (
                          <div className="flex flex-wrap gap-1.5 mt-2">
                            {room.equipment.map((eq, i) => (
                              <span key={i} className="px-2 py-0.5 bg-surface-lighter rounded text-text-muted text-[0.65rem]">{eq.name}</span>
                            ))}
                          </div>
                        )}
                      </div>
                      <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                        selectedRoom === room.id ? 'border-accent bg-accent' : 'border-border'
                      }`}>
                        {selectedRoom === room.id && <div className="w-2 h-2 bg-primary rounded-full" />}
                      </div>
                    </div>
                  </div>
                ))}
                {studio.rooms.filter(r => r.is_active).length === 0 && (
                  <p className="text-text-muted text-sm text-center py-4">Belum ada ruangan tersedia</p>
                )}
              </div>
            </div>

            {/* Opening Hours */}
            {studio.opening_hours && studio.opening_hours.length > 0 && (
              <div className="card-luxury p-6 animate-fade-in-up stagger-2">
                <h2 className="text-base font-semibold text-text-primary mb-4">🕐 Jam Operasional</h2>
                <div className="grid grid-cols-2 gap-2">
                  {studio.opening_hours.map((oh) => (
                    <div key={oh.day} className="flex items-center justify-between py-2 px-3 rounded-lg bg-surface-light/30 text-sm">
                      <span className="text-text-secondary capitalize">{oh.day}</span>
                      <span className={`font-medium ${oh.is_closed ? 'text-danger' : 'text-text-primary'}`}>
                        {oh.is_closed ? 'Tutup' : `${oh.open_time} – ${oh.close_time}`}
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Facilities */}
            {studio.facilities && studio.facilities.length > 0 && (
              <div className="card-luxury p-6 animate-fade-in-up stagger-3">
                <h2 className="text-base font-semibold text-text-primary mb-4">✨ Fasilitas</h2>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {studio.facilities.map((facility) => (
                    <div key={facility.id} className="rounded-xl border border-border/40 bg-surface-light/40 overflow-hidden hover:border-accent/20 transition-all">
                      {facility.image ? (
                        <img src={facility.image} alt={facility.name} loading="lazy" className="w-full h-24 object-cover" />
                      ) : (
                        <div className="w-full h-16 flex items-center justify-center text-3xl bg-surface-lighter/50">
                          {facility.icon || '✨'}
                        </div>
                      )}
                      <div className="p-3">
                        <p className="text-text-primary text-sm font-semibold flex items-center gap-1.5">
                          {facility.icon && !facility.image && <span>{facility.icon}</span>}
                          <span className="truncate">{facility.name}</span>
                        </p>
                        {facility.description && (
                          <p className="text-text-muted text-xs mt-0.5 line-clamp-2 leading-relaxed">{facility.description}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right: Booking Form */}
          <div className="space-y-6">
            <form onSubmit={handleBooking} className="card-luxury p-6 animate-fade-in-up stagger-1 sticky top-6">
              <h2 className="text-base font-semibold text-text-primary mb-4">📅 Booking Sekarang</h2>

              {bookingError && (
                <div className="mb-4 p-3 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">
                  {bookingError}
                </div>
              )}

              <div className="space-y-4">
                {/* Selected Room */}
                <div>
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Ruangan</label>
                  <p className="text-text-primary text-sm mt-1 font-medium">
                    {selectedRoom ? studio.rooms.find(r => r.id === selectedRoom)?.name : '← Pilih ruangan di sebelah kiri'}
                  </p>
                </div>

                {/* Date */}
                <div>
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Tanggal *</label>
                  <input
                    type="date"
                    value={date}
                    min={today}
                    onChange={(e) => setDate(e.target.value)}
                    className="input-luxury w-full mt-1 text-sm"
                    required
                  />
                </div>

                {/* Time */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Jam Mulai *</label>
                    <input
                      type="time"
                      value={startTime}
                      onChange={(e) => setStartTime(e.target.value)}
                      className="input-luxury w-full mt-1 text-sm"
                      required
                    />
                  </div>
                  <div>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Jam Selesai *</label>
                    <input
                      type="time"
                      value={endTime}
                      onChange={(e) => setEndTime(e.target.value)}
                      className="input-luxury w-full mt-1 text-sm"
                      required
                    />
                  </div>
                </div>

                {/* Promo Code */}
                <div>
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kode Promo</label>
                  <input
                    type="text"
                    value={promoCode}
                    onChange={(e) => setPromoCode(e.target.value)}
                    placeholder="Opsional"
                    className="input-luxury w-full mt-1 text-sm"
                  />
                </div>

                {/* Notes */}
                <div>
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Catatan</label>
                  <textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder="Opsional..."
                    rows={3}
                    className="input-luxury w-full mt-1 text-sm resize-none"
                  />
                </div>

                {/* Estimated Price */}
                {estimatedPrice !== null && (
                  <div className="p-3 rounded-xl bg-accent/[0.05] border border-accent/10">
                    <p className="text-text-muted text-xs">Estimasi Harga</p>
                    <p className="text-xl font-bold gold-text-static mt-1">{formatCurrency(estimatedPrice)}</p>
                  </div>
                )}

                {/* Submit */}
                <button
                  type="submit"
                  disabled={!selectedRoom || !date || !startTime || !endTime || bookingLoading}
                  className="btn-gold w-full py-3 text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  {bookingLoading ? (
                    <span className="flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
                      Memproses...
                    </span>
                  ) : 'Booking Sekarang'}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* Reviews & Rating */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-2">
          <h2 className="text-base font-semibold text-text-primary mb-6">⭐ Ulasan & Rating</h2>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Rating summary */}
            <div>
              <div className="text-center lg:text-left">
                <p className="text-5xl font-bold gold-text-static">
                  {reviewSummary ? Number(reviewSummary.average_rating).toFixed(1) : '–'}
                </p>
                <div className="flex items-center justify-center lg:justify-start gap-1 mt-2">
                  {[1, 2, 3, 4, 5].map((s) => (
                    <span
                      key={s}
                      className={`text-sm ${s <= Math.round(reviewSummary?.average_rating || 0) ? 'text-warning' : 'text-text-muted/30'}`}
                    >
                      ★
                    </span>
                  ))}
                </div>
                <p className="text-text-muted text-xs mt-1">dari {reviewSummary?.total_reviews ?? 0} ulasan</p>
              </div>

              {/* Rating distribution */}
              <div className="space-y-1.5 mt-6">
                {[5, 4, 3, 2, 1].map((r) => {
                  const count = reviewSummary?.rating_distribution?.[r] ?? 0
                  const pct = reviewSummary?.total_reviews ? Math.round((count / reviewSummary.total_reviews) * 100) : 0
                  return (
                    <div key={r} className="flex items-center gap-2 text-xs">
                      <span className="w-3 text-text-muted text-right">{r}</span>
                      <span className="text-warning">★</span>
                      <div className="flex-1 h-1.5 bg-surface-lighter rounded-full overflow-hidden">
                        <div
                          className="h-full bg-warning rounded-full transition-all duration-500"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="text-text-muted w-6 text-right">{count}</span>
                    </div>
                  )
                })}
              </div>
            </div>

            {/* Rating form */}
            <div>
              <h3 className="text-text-primary font-semibold text-sm mb-3">Beri Rating</h3>
              {completedBookings.length > 0 ? (
                <form onSubmit={handleSubmitReview} className="space-y-4">
                  {reviewSuccess && (
                    <div className="p-3 bg-success/10 border border-success/20 rounded-xl text-success text-sm">
                      ✓ Rating berhasil dikirim. Terima kasih!
                    </div>
                  )}
                  {reviewError && (
                    <div className="p-3 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">
                      {reviewError}
                    </div>
                  )}
                  <div>
                    <label className="block text-text-secondary text-xs font-medium tracking-wide uppercase mb-1.5">
                      Pilih Booking Selesai
                    </label>
                    <select
                      value={reviewBookingId || ''}
                      onChange={(e) => setReviewBookingId(e.target.value ? Number(e.target.value) : null)}
                      className="input-luxury w-full text-sm"
                      required
                    >
                      <option value="">Pilih booking...</option>
                      {completedBookings.map((b) => (
                        <option key={b.id} value={b.id}>
                          {b.booking_code} — {new Date(b.date).toLocaleDateString('id-ID')}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-text-secondary text-xs font-medium tracking-wide uppercase mb-1.5">Rating</label>
                    <div className="flex items-center gap-1">
                      {[1, 2, 3, 4, 5].map((s) => (
                        <button
                          key={s}
                          type="button"
                          onClick={() => setReviewRating(s)}
                          className={`text-2xl transition-transform hover:scale-110 ${s <= reviewRating ? 'text-warning' : 'text-text-muted/25'}`}
                        >
                          ★
                        </button>
                      ))}
                      <span className="text-text-muted text-xs ml-2">{reviewRating}/5</span>
                    </div>
                  </div>
                  <div>
                    <label className="block text-text-secondary text-xs font-medium tracking-wide uppercase mb-1.5">Komentar</label>
                    <textarea
                      value={reviewComment}
                      onChange={(e) => setReviewComment(e.target.value)}
                      placeholder="Ceritakan pengalaman Anda (opsional)"
                      rows={3}
                      maxLength={1000}
                      className="input-luxury w-full text-sm resize-none"
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={reviewSubmitting}
                    className="btn-gold w-full py-3 text-sm font-semibold disabled:opacity-40 disabled:cursor-not-allowed"
                  >
                    {reviewSubmitting ? 'Mengirim...' : 'Kirim Rating'}
                  </button>
                </form>
              ) : (
                <p className="text-text-muted text-sm leading-relaxed">
                  Selesaikan pemesanan di studio ini untuk memberi rating dan ulasan.
                </p>
              )}
            </div>

            {/* Reviews list */}
            <div>
              <h3 className="text-text-primary font-semibold text-sm mb-3">Ulasan Terbaru</h3>
              {reviewsLoading ? (
                <p className="text-text-muted text-sm">Memuat ulasan...</p>
              ) : reviews.length === 0 ? (
                <p className="text-text-muted text-sm">Belum ada ulasan untuk studio ini.</p>
              ) : (
                <div className="space-y-4 max-h-80 overflow-y-auto pr-1">
                  {reviews.map((r) => (
                    <div key={r.id} className="border-b border-border/30 pb-4 last:border-0">
                      <div className="flex items-center justify-between gap-2">
                        <p className="text-text-primary text-sm font-semibold truncate">{r.user?.name}</p>
                        <span className="text-warning text-xs whitespace-nowrap">
                          {'★'.repeat(r.rating)}{'☆'.repeat(5 - r.rating)}
                        </span>
                      </div>
                      {r.comment && <p className="text-text-secondary text-sm mt-1 leading-relaxed">{r.comment}</p>}
                      <p className="text-text-muted text-xs mt-1.5">
                        {new Date(r.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
