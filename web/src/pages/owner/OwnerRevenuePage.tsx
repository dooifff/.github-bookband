import { useState, useEffect } from 'react'
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

  useEffect(() => {
    fetchRevenue()
  }, [period])

  const fetchRevenue = async () => {
    setLoading(true)
    try {
      const response = await api.get(`/owner/revenue?period=${period}`)
      setData(response.data.data)
    } catch (error) {
      console.error('Failed to fetch revenue:', error)
    } finally {
      setLoading(false)
    }
  }

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
    }).format(amount)
  }

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent">Loading revenue data...</div>
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
            <h1 className="text-2xl font-bold text-text-primary">Revenue</h1>
            <p className="text-text-secondary">Track your earnings and analytics</p>
          </div>
          <select
            value={period}
            onChange={(e) => setPeriod(e.target.value)}
            className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
          >
            <option value="week">This Week</option>
            <option value="month">This Month</option>
            <option value="year">This Year</option>
          </select>
        </div>

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-surface border border-border rounded-xl p-6">
            <p className="text-text-muted text-sm">Total Revenue</p>
            <p className="text-2xl font-bold text-text-primary mt-1">
              {formatCurrency(data?.summary?.total_revenue || 0)}
            </p>
          </div>
          <div className="bg-surface border border-border rounded-xl p-6">
            <p className="text-text-muted text-sm">This Month</p>
            <p className="text-2xl font-bold text-success mt-1">
              {formatCurrency(data?.summary?.this_month || 0)}
            </p>
          </div>
          <div className="bg-surface border border-border rounded-xl p-6">
            <p className="text-text-muted text-sm">Pending</p>
            <p className="text-2xl font-bold text-warning mt-1">
              {formatCurrency(data?.summary?.pending || 0)}
            </p>
          </div>
          <div className="bg-surface border border-border rounded-xl p-6">
            <p className="text-text-muted text-sm">Refunded</p>
            <p className="text-2xl font-bold text-error mt-1">
              {formatCurrency(data?.summary?.refunded || 0)}
            </p>
          </div>
        </div>

        {/* Revenue by Studio */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Revenue by Studio</h2>
          <div className="space-y-4">
            {data?.by_studio?.map((studio) => (
              <div key={studio.id} className="flex items-center justify-between py-3 border-b border-border last:border-0">
                <div>
                  <p className="text-text-primary font-medium">{studio.name}</p>
                  <p className="text-text-muted text-sm">{studio.bookings_count} bookings</p>
                </div>
                <div className="text-right">
                  <p className="text-text-primary font-semibold">{formatCurrency(studio.total_revenue)}</p>
                  <p className="text-text-muted text-sm">{studio.percentage}%</p>
                </div>
              </div>
            ))}
            {(!data?.by_studio || data.by_studio.length === 0) && (
              <p className="text-text-muted text-center py-4">No revenue data</p>
            )}
          </div>
        </div>

        {/* Monthly Revenue */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Monthly Revenue</h2>
          <div className="space-y-3">
            {data?.monthly?.slice(0, 12).map((month) => (
              <div key={month.month} className="flex items-center gap-4">
                <span className="text-text-secondary w-20">{month.label}</span>
                <div className="flex-1 bg-surface-light rounded-full h-6 overflow-hidden">
                  <div
                    className="bg-accent h-full rounded-full transition-all"
                    style={{ width: `${month.percentage}%` }}
                  />
                </div>
                <span className="text-text-primary font-medium w-32 text-right">
                  {formatCurrency(month.amount)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Payment Methods */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">Payment Methods</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {data?.by_payment_method?.map((method) => (
              <div key={method.method} className="text-center p-4 bg-surface-light rounded-lg">
                <p className="text-text-muted text-sm capitalize">{method.method}</p>
                <p className="text-xl font-bold text-text-primary mt-1">{method.count}</p>
                <p className="text-text-muted text-xs">transactions</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
