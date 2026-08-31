import { useState, useEffect, useCallback } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Booking {
  id: number
  booking_code: string
  studio: { name: string }
  room: { name: string }
  date: string
  start_time: string
  end_time: string
  duration_hours: number
  pricing: { total: string; formatted_total: string; subtotal: string; discount: string }
}

interface Payment {
  payment_code: string
  amount: number
  status: string
  payment_url: string
  snap_token: string
  expired_at: string
}

export default function PaymentPage() {
  const { bookingCode } = useParams<{ bookingCode: string }>()
  const navigate = useNavigate()
  const [booking, setBooking] = useState<Booking | null>(null)
  const [payment, setPayment] = useState<Payment | null>(null)
  const [loading, setLoading] = useState(true)
  const [processing, setProcessing] = useState(false)
  const [error, setError] = useState('')
  const [selectedMethod, setSelectedMethod] = useState('bank_transfer')

  const fetchBooking = useCallback(async () => {
    try {
      const response = await api.get(`/bookings/code/${bookingCode}`)
      setBooking(response.data.data)
    } catch (err: any) {
      console.error('Failed to fetch booking:', err)
      setError(err.response?.data?.message || 'Booking tidak ditemukan')
    } finally {
      setLoading(false)
    }
  }, [bookingCode])

  useEffect(() => { fetchBooking() }, [fetchBooking])

  const handlePayment = async () => {
    if (!booking) return

    setProcessing(true)
    setError('')

    try {
      const response = await api.post('/payments', {
        booking_id: booking.id,
        method: selectedMethod,
        provider: 'midtrans',
      })

      if (response.data.success) {
        const paymentData = response.data.data
        setPayment(paymentData)

        // Open Midtrans Snap popup
        if (paymentData.snap_token) {
          openSnapPopup(paymentData.snap_token)
        } else if (paymentData.payment_url) {
          // Fallback to redirect
          window.location.href = paymentData.payment_url
        }
      }
    } catch (err: any) {
      console.error('Payment error:', err)
      setError(err.response?.data?.message || 'Gagal memproses pembayaran')
    } finally {
      setProcessing(false)
    }
  }

  const openSnapPopup = (snapToken: string) => {
    // Load Midtrans Snap JS if not already loaded
    if (typeof window.snap === 'undefined') {
      const script = document.createElement('script')
      script.src = import.meta.env.VITE_MIDTRANS_SNAP_URL || 'https://app.sandbox.midtrans.com/snap/snap.js'
      script.setAttribute('data-client-key', import.meta.env.VITE_MIDTRANS_CLIENT_KEY || '')
      script.onload = () => {
        window.snap.pay(snapToken, {
          onSuccess: (result: any) => {
            console.log('Payment success:', result)
            navigate('/customer/bookings')
          },
          onPending: (result: any) => {
            console.log('Payment pending:', result)
            setPayment(prev => prev ? { ...prev, status: 'pending' } : null)
          },
          onError: (result: any) => {
            console.error('Payment error:', result)
            setError('Pembayaran gagal. Silakan coba lagi.')
          },
          onClose: () => {
            console.log('Payment popup closed')
            setError('Anda menutup popup pembayaran.')
          },
        })
      }
      document.head.appendChild(script)
    } else {
      window.snap.pay(snapToken, {
        onSuccess: (result: any) => {
          console.log('Payment success:', result)
          navigate('/customer/bookings')
        },
        onPending: (result: any) => {
          console.log('Payment pending:', result)
          setPayment(prev => prev ? { ...prev, status: 'pending' } : null)
        },
        onError: (result: any) => {
          console.error('Payment error:', result)
          setError('Pembayaran gagal. Silakan coba lagi.')
        },
        onClose: () => {
          console.log('Payment popup closed')
          setError('Anda menutup popup pembayaran.')
        },
      })
    }
  }

  const paymentMethods = [
    { id: 'bank_transfer', label: 'Transfer Bank', icon: '🏦', desc: 'BCA, Mandiri, BRI, BNI' },
    { id: 'ewallet', label: 'E-Wallet', icon: '📱', desc: 'GoPay, ShopeePay, OVO, DANA' },
    { id: 'credit_card', label: 'Kartu Kredit', icon: '💳', desc: 'Visa, Mastercard, JCB' },
    { id: 'qris', label: 'QRIS', icon: '📲', desc: 'Scan QR dari semua bank' },
  ]

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat detail pembayaran...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (error && !booking) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <span className="text-4xl block mb-4">❌</span>
            <p className="text-danger mb-4">{error}</p>
            <button onClick={() => navigate('/customer/bookings')} className="btn-gold text-sm">Kembali</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="max-w-2xl mx-auto space-y-6">
        {/* Back button */}
        <button onClick={() => navigate('/customer/bookings')} className="flex items-center gap-2 text-text-secondary hover:text-text-primary transition-colors text-sm">
          ← Kembali ke Pemesanan
        </button>

        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-2xl font-bold text-text-primary">💰 Pembayaran</h1>
          <p className="text-text-secondary mt-1 text-sm">Selesaikan pembayaran untuk booking Anda</p>
        </div>

        {/* Booking Summary */}
        {booking && (
          <div className="card-luxury p-6 animate-fade-in-up stagger-1">
            <h2 className="text-base font-semibold text-text-primary mb-4">Ringkasan Booking</h2>
            <div className="space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Kode Booking</span>
                <span className="font-mono text-accent font-medium">{booking.booking_code}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Studio</span>
                <span className="text-text-primary">{booking.studio?.name}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Ruangan</span>
                <span className="text-text-primary">{booking.room?.name}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Tanggal</span>
                <span className="text-text-primary">{new Date(booking.date).toLocaleDateString('id-ID')}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Waktu</span>
                <span className="text-text-primary">{booking.start_time} – {booking.end_time}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-text-muted">Durasi</span>
                <span className="text-text-primary">{booking.duration_hours} jam</span>
              </div>
              <div className="divider-gold my-2" />
              <div className="flex justify-between text-lg font-bold">
                <span className="text-text-primary">Total</span>
                <span className="gold-text-static">{booking.pricing?.formatted_total}</span>
              </div>
            </div>
          </div>
        )}

        {/* Payment Method Selection */}
        {!payment && (
          <div className="card-luxury p-6 animate-fade-in-up stagger-2">
            <h2 className="text-base font-semibold text-text-primary mb-4">Metode Pembayaran</h2>

            {error && (
              <div className="mb-4 p-3 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">
                {error}
              </div>
            )}

            <div className="space-y-3">
              {paymentMethods.map((method) => (
                <div
                  key={method.id}
                  onClick={() => setSelectedMethod(method.id)}
                  className={`p-4 rounded-xl border cursor-pointer transition-all ${
                    selectedMethod === method.id
                      ? 'border-accent bg-accent/[0.05]'
                      : 'border-border/50 hover:border-border-light'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{method.icon}</span>
                    <div className="flex-1">
                      <p className="text-text-primary font-medium text-sm">{method.label}</p>
                      <p className="text-text-muted text-xs">{method.desc}</p>
                    </div>
                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center ${
                      selectedMethod === method.id ? 'border-accent bg-accent' : 'border-border'
                    }`}>
                      {selectedMethod === method.id && <div className="w-2 h-2 bg-primary rounded-full" />}
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Pay Button */}
            <button
              onClick={handlePayment}
              disabled={processing}
              className="btn-gold w-full py-3 text-sm font-semibold mt-6 disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {processing ? (
                <span className="flex items-center justify-center gap-2">
                  <div className="w-4 h-4 border-2 border-primary/30 border-t-primary rounded-full animate-spin" />
                  Memproses...
                </span>
              ) : `Bayar ${booking?.pricing?.formatted_total || ''}`}
            </button>

            <p className="text-text-muted text-xs text-center mt-3">
              Pembayaran diproses secara aman oleh Midtrans
            </p>
          </div>
        )}

        {/* Payment Pending */}
        {payment && payment.status === 'pending' && (
          <div className="card-luxury p-6 animate-fade-in-up stagger-2">
            <div className="text-center">
              <span className="text-4xl block mb-4">⏳</span>
              <h3 className="text-lg font-semibold text-text-primary mb-2">Menunggu Pembayaran</h3>
              <p className="text-text-muted text-sm mb-4">
                Selesaikan pembayaran sebelum {payment.expired_at ? new Date(payment.expired_at).toLocaleString('id-ID') : '24 jam'}
              </p>
              <div className="flex gap-3 justify-center">
                <button
                  onClick={() => payment.snap_token && openSnapPopup(payment.snap_token)}
                  className="btn-gold text-sm"
                >
                  💳 Bayar Sekarang
                </button>
                <button
                  onClick={() => navigate('/customer/bookings')}
                  className="btn-glass text-sm"
                >
                  Nanti Saja
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Payment Success */}
        {payment && payment.status === 'paid' && (
          <div className="card-luxury p-6 animate-fade-in-up stagger-2">
            <div className="text-center">
              <span className="text-5xl block mb-4">✅</span>
              <h3 className="text-lg font-semibold text-text-primary mb-2">Pembayaran Berhasil!</h3>
              <p className="text-text-muted text-sm mb-4">
                Booking Anda telah terkonfirmasi.
              </p>
              <button
                onClick={() => navigate('/customer/bookings')}
                className="btn-gold text-sm"
              >
                Lihat Pemesanan
              </button>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}

// Declare snap type for TypeScript
declare global {
  interface Window {
    snap: {
      pay: (token: string, options: {
        onSuccess?: (result: any) => void
        onPending?: (result: any) => void
        onError?: (result: any) => void
        onClose?: () => void
      }) => void
    }
  }
}
