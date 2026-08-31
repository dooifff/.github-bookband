import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface RevenueData {
  summary: {
    total_revenue: number
    this_month: number
    last_month: number
    this_year: number
    pending: number
    refunded: number
  }
  by_studio: any[]
  monthly: any[]
  by_payment_method: any[]
}

export default function OwnerRevenuePage() {
  const [data, setData] = useState<RevenueData | null>(null)
  const [loading, setLoading] = useState(true)
  const [period, setPeriod] = useState('month')

  const fetchRevenue = useCallback(async () => {
    setLoading(true)
    try {
      const response = await api.get(`/owner/revenue?period=${period}`)
      setData(response.data.data)
    } catch (error) {
      console.error('Failed to fetch revenue:', error)
    } finally {
      setLoading(false)
    }
  }, [period])

  useEffect(() => { fetchRevenue() }, [fetchRevenue])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat data pendapatan...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-8">
        {/* Header */}
        <div className="flex items-center justify-between animate-fade-in-up">
          <div>
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Pendapatan</h1>
            <p className="text-text-secondary mt-1 text-sm">Pantau penghasilan dan analitik Anda</p>
          </div>
          <select value={period} onChange={(e) => setPeriod(e.target.value)} className="select-luxury text-sm">
            <option value="week">Minggu Ini</option>
            <option value="month">Bulan Ini</option>
            <option value="year">Tahun Ini</option>
          </select>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
          {[
            { label: 'Total Pendapatan', value: formatCurrency(data?.summary?.total_revenue || 0), color: 'text-text-primary' },
            { label: 'Bulan Ini', value: formatCurrency(data?.summary?.this_month || 0), color: 'text-success' },
            { label: 'Menunggu', value: formatCurrency(data?.summary?.pending || 0), color: 'text-warning' },
            { label: 'Dikembalikan', value: formatCurrency(data?.summary?.refunded || 0), color: 'text-danger' },
          ].map((card, i) => (
            <div key={card.label} className={`card-luxury p-6 animate-fade-in-up stagger-${i + 1}`}>
              <p className="text-text-muted text-xs font-medium tracking-wide uppercase">{card.label}</p>
              <p className={`text-2xl font-bold mt-2 tracking-tight ${card.color}`}>{card.value}</p>
            </div>
          ))}
        </div>

        {/* Revenue by Studio */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-5">
          <h2 className="text-base font-semibold text-text-primary mb-5">Pendapatan per Studio</h2>
          <div className="space-y-1">
            {data?.by_studio?.map((studio) => (
              <div key={studio.id} className="flex items-center justify-between py-3 px-3 -mx-3 rounded-xl hover:bg-surface-lighter/40 transition-colors">
                <div>
                  <p className="text-text-primary text-sm font-medium">{studio.name}</p>
                  <p className="text-text-muted text-xs">{studio.bookings_count} pemesanan</p>
                </div>
                <div className="text-right">
                  <p className="text-text-primary text-sm font-semibold">{formatCurrency(studio.total_revenue)}</p>
                  <p className="text-text-muted text-xs">{studio.percentage}%</p>
                </div>
              </div>
            ))}
            {(!data?.by_studio || data.by_studio.length === 0) && (
              <p className="text-text-muted text-center py-8 text-sm">Tidak ada data pendapatan</p>
            )}
          </div>
        </div>

        {/* Monthly Revenue */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-6">
          <h2 className="text-base font-semibold text-text-primary mb-5">Pendapatan Bulanan</h2>
          <div className="space-y-3">
            {data?.monthly?.slice(0, 12).map((month) => (
              <div key={month.month} className="flex items-center gap-4">
                <span className="text-text-secondary text-xs w-20 font-medium">{month.label}</span>
                <div className="flex-1 bg-surface-lighter rounded-full h-5 overflow-hidden">
                  <div className="h-full rounded-full bg-gradient-to-r from-accent/60 to-accent transition-all duration-500" style={{ width: `${month.percentage}%` }} />
                </div>
                <span className="text-text-primary text-sm font-medium w-32 text-right">{formatCurrency(month.amount)}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Payment Methods */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-7">
          <h2 className="text-base font-semibold text-text-primary mb-5">Metode Pembayaran</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {data?.by_payment_method?.map((method) => (
              <div key={method.method} className="text-center p-4 rounded-xl bg-surface-light/50 border border-border/50">
                <p className="text-text-muted text-xs capitalize font-medium">{method.method}</p>
                <p className="text-xl font-bold text-text-primary mt-2">{method.count}</p>
                <p className="text-text-muted text-[0.65rem] mt-0.5">transaksi</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
