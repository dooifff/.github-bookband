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

  const fetchStudio = useCallback(async () => {
    try {
      const response = await api.get(`/studios/${slug}`)
      setStudio(response.data.data)
    } catch (err: any) {
      console.error('Failed to fetch studio:', err)
      setError(err.response?.data?.message || 'Studio tidak ditemukan')
    } finally {
      setLoading(false)
    }
  }, [slug])

  useEffect(() => { fetchStudio() }, [fetchStudio])

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
      </div>
    </AdminLayout>
  )
}
