import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface PeriodStats { avg: number; min: number; max: number }
interface MetricComparison { period1: PeriodStats; period2: PeriodStats; change: { absolute: number; percent: number; direction: 'increased' | 'decreased' | 'unchanged' }; regression: boolean }
interface ComparisonResult {
  period1: { start: string; end: string; stats: { count: number; avg: Record<string, number> } }
  period2: { start: string; end: string; stats: { count: number; avg: Record<string, number> } }
  comparison: Record<string, MetricComparison>
  summary: { has_regressions: boolean; regression_count: number; improvement_count: number; regressions: Array<{ metric: string; change: number }>; improvements: Array<{ metric: string; change: number }> }
}
interface TrendData { date: string; avg: number; min: number; max: number; count: number }

export default function ComparisonDashboard() {
  const [comparison, setComparison] = useState<ComparisonResult | null>(null)
  const [trends, setTrends] = useState<Record<string, TrendData[]>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [period1Start, setPeriod1Start] = useState(getDateDaysAgo(7))
  const [period1End, setPeriod1End] = useState(getDateDaysAgo(1))
  const [period2Start, setPeriod2Start] = useState(getDateDaysAgo(14))
  const [period2End, setPeriod2End] = useState(getDateDaysAgo(8))

  function getDateDaysAgo(days: number): string {
    const date = new Date()
    date.setDate(date.getDate() - days)
    return date.toISOString().split('T')[0]
  }

  const fetchComparison = useCallback(async () => {
    try {
      setLoading(true)
      setError('')
      const [compareRes, ...trendRes] = await Promise.all([
        api.post('/admin/performance/compare', { period1_start: period1Start, period1_end: period1End, period2_start: period2Start, period2_end: period2End }),
        api.get('/admin/performance/compare/trend/cpu?days=30'),
        api.get('/admin/performance/compare/trend/memory?days=30'),
        api.get('/admin/performance/compare/trend/response_time?days=30'),
        api.get('/admin/performance/compare/trend/disk?days=30'),
      ])
      setComparison(compareRes.data.data)
      setTrends({ cpu: trendRes[0].data.data.trend, memory: trendRes[1].data.data.trend, response_time: trendRes[2].data.data.trend, disk: trendRes[3].data.data.trend })
    } catch (err: any) {
      console.error('Failed to fetch comparison:', err)
      setError(err.response?.data?.message || 'Failed to load comparison data')
    } finally {
      setLoading(false)
    }
  }, [period1Start, period1End, period2Start, period2End])

  useEffect(() => { fetchComparison() }, [fetchComparison])

  const exportReport = async (format: 'json' | 'markdown' | 'csv' | 'pdf') => {
    try {
      const response = await api.post('/admin/performance/compare/export', { period1_start: period1Start, period1_end: period1End, period2_start: period2Start, period2_end: period2End, format }, { responseType: 'blob' })
      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      link.setAttribute('download', `performance-report.${format === 'markdown' ? 'md' : format}`)
      document.body.appendChild(link)
      link.click()
      link.remove()
    } catch { console.error('Failed to export') }
  }

  const sendEmailReport = async () => {
    const email = prompt('Enter email address to send report:')
    if (!email) return
    try {
      await api.post('/admin/performance/email/send', { recipient: email, period1_start: period1Start, period1_end: period1End, period2_start: period2Start, period2_end: period2End, attach_pdf: true })
      alert('Report sent successfully!')
    } catch { alert('Failed to send report') }
  }

  const getChangeColor = (change: MetricComparison['change']) => {
    if (change.direction === 'unchanged') return 'text-text-muted'
    if (change.direction === 'decreased') return 'text-success'
    return change.percent > 20 ? 'text-danger' : 'text-warning'
  }

  const getChangeIcon = (change: MetricComparison['change']) => {
    if (change.direction === 'unchanged') return '→'
    if (change.direction === 'decreased') return '↓'
    return '↑'
  }

  const formatValue = (metric: string, value: number): string => {
    if (metric.includes('time') || metric === 'response_time') return `${value.toFixed(1)}ms`
    if (metric === 'error_rate' || metric.includes('rate')) return `${value.toFixed(2)}%`
    if (metric === 'requests_per_second') return `${value.toFixed(0)} req/s`
    return `${value.toFixed(1)}%`
  }

  if (loading && !comparison) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat data perbandingan...</p>
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
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Perbandingan Performa</h1>
            <p className="text-text-secondary mt-1 text-sm">Bandingkan metrik performa di berbagai periode waktu</p>
          </div>
          <div className="flex items-center gap-2">
            {[
              { format: 'json' as const, label: '📄 JSON' },
              { format: 'csv' as const, label: '📊 CSV' },
              { format: 'pdf' as const, label: '📕 PDF' },
            ].map((btn) => (
              <button key={btn.format} onClick={() => exportReport(btn.format)} className="btn-glass text-xs py-1.5 px-3">{btn.label}</button>
            ))}
            <button onClick={sendEmailReport} className="btn-gold text-xs py-1.5 px-3">📧 Email</button>
          </div>
        </div>

        {/* Date Selection */}
        <div className="card-luxury p-6 animate-fade-in-up stagger-1">
          <h2 className="text-base font-semibold text-text-primary mb-4">📅 Pilih Periode Waktu</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="p-4 rounded-xl bg-surface-light/50 border border-border/30">
              <h3 className="text-text-primary text-sm font-medium mb-3">Periode 1 (Terbaru)</h3>
              <div className="grid grid-cols-2 gap-3">
                <div><label className="text-text-muted text-xs">Start</label><input type="date" value={period1Start} onChange={(e) => setPeriod1Start(e.target.value)} className="input-luxury w-full mt-1 text-sm" /></div>
                <div><label className="text-text-muted text-xs">End</label><input type="date" value={period1End} onChange={(e) => setPeriod1End(e.target.value)} className="input-luxury w-full mt-1 text-sm" /></div>
              </div>
            </div>
            <div className="p-4 rounded-xl bg-surface-light/50 border border-border/30">
              <h3 className="text-text-primary text-sm font-medium mb-3">Periode 2 (Sebelumnya)</h3>
              <div className="grid grid-cols-2 gap-3">
                <div><label className="text-text-muted text-xs">Start</label><input type="date" value={period2Start} onChange={(e) => setPeriod2Start(e.target.value)} className="input-luxury w-full mt-1 text-sm" /></div>
                <div><label className="text-text-muted text-xs">End</label><input type="date" value={period2End} onChange={(e) => setPeriod2End(e.target.value)} className="input-luxury w-full mt-1 text-sm" /></div>
              </div>
            </div>
          </div>
          <div className="mt-4 flex justify-end"><button onClick={fetchComparison} className="btn-gold text-sm">🔄 Bandingkan Periode</button></div>
        </div>

        {error && <div className="p-4 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">{error}</div>}

        {comparison && (
          <>
            {/* Summary */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-5">
              <div className="card-luxury p-5 animate-fade-in-up"><p className="text-text-muted text-xs font-medium uppercase">Period 1 Snapshots</p><p className="text-2xl font-bold text-text-primary mt-2">{comparison.period1.stats.count}</p><p className="text-text-muted text-xs mt-1">{comparison.period1.start} to {comparison.period1.end}</p></div>
              <div className="card-luxury p-5 animate-fade-in-up stagger-1"><p className="text-text-muted text-xs font-medium uppercase">Period 2 Snapshots</p><p className="text-2xl font-bold text-text-primary mt-2">{comparison.period2.stats.count}</p><p className="text-text-muted text-xs mt-1">{comparison.period2.start} to {comparison.period2.end}</p></div>
              <div className={`card-luxury p-5 animate-fade-in-up stagger-2 ${comparison.summary.has_regressions ? 'border-danger/20' : 'border-success/20'}`}>
                <p className="text-text-muted text-xs font-medium uppercase">Regressions</p>
                <p className={`text-2xl font-bold mt-2 ${comparison.summary.has_regressions ? 'text-danger' : 'text-success'}`}>{comparison.summary.regression_count}</p>
              </div>
              <div className="card-luxury p-5 animate-fade-in-up stagger-3"><p className="text-text-muted text-xs font-medium uppercase">Improvements</p><p className="text-2xl font-bold text-success mt-2">{comparison.summary.improvement_count}</p></div>
            </div>

            {comparison.summary.has_regressions && (
              <div className="p-4 bg-danger/8 border border-danger/20 rounded-xl animate-fade-in">
                <h3 className="text-danger text-sm font-semibold mb-2">⚠️ Performance Regressions Detected</h3>
                <ul className="list-disc list-inside text-danger text-sm">
                  {comparison.summary.regressions.map((reg, i) => <li key={i}>{reg.metric}: +{reg.change.toFixed(1)}%</li>)}
                </ul>
              </div>
            )}

            {/* Comparison Table */}
            <div className="card-luxury overflow-hidden animate-fade-in-up stagger-4">
              <div className="px-6 py-4 border-b border-border/40">
                <h2 className="text-base font-semibold text-text-primary">📊 Metric Comparison</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full table-luxury">
                  <thead>
                    <tr>
                      <th className="text-left">Metric</th>
                      <th className="text-right">Period 1 Avg</th>
                      <th className="text-right">Period 2 Avg</th>
                      <th className="text-right">Change</th>
                      <th className="text-center">Status</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-border/30">
                    {Object.entries(comparison.comparison).map(([metric, data]) => (
                      <tr key={metric}>
                        <td className="text-text-primary text-sm font-medium capitalize">{metric.replace(/_/g, ' ')}</td>
                        <td className="text-right text-text-secondary text-sm">{formatValue(metric, data.period1.avg)}</td>
                        <td className="text-right text-text-secondary text-sm">{formatValue(metric, data.period2.avg)}</td>
                        <td className={`text-right text-sm font-medium ${getChangeColor(data.change)}`}>{getChangeIcon(data.change)} {Math.abs(data.change.percent).toFixed(1)}%</td>
                        <td className="text-center">
                          <span className={`badge ${data.regression ? 'bg-danger/10 text-danger border border-danger/20' : 'bg-success/10 text-success border border-success/20'}`}>
                            {data.regression ? 'Regression' : 'OK'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Trends */}
            {Object.keys(trends).length > 0 && (
              <div className="card-luxury p-6 animate-fade-in-up stagger-5">
                <h2 className="text-base font-semibold text-text-primary mb-5">📈 30-Day Trends</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
                  {Object.entries(trends).map(([metric, data]) => (
                    <div key={metric} className="p-4 rounded-xl bg-surface-light/50 border border-border/30">
                      <h3 className="text-text-primary text-sm font-medium mb-2 capitalize">{metric.replace(/_/g, ' ')}</h3>
                      {data.length > 0 ? (
                        <>
                          <div className="flex justify-between text-xs text-text-muted mb-2">
                            <span>Min: {formatValue(metric, Math.min(...data.map(d => d.min)))}</span>
                            <span>Avg: {formatValue(metric, data.reduce((a, b) => a + b.avg, 0) / data.length)}</span>
                            <span>Max: {formatValue(metric, Math.max(...data.map(d => d.max)))}</span>
                          </div>
                          <div className="h-1.5 bg-surface-lighter rounded-full overflow-hidden">
                            <div className="h-full bg-accent/60 rounded-full" style={{ width: `${Math.min(100, (data.reduce((a, b) => a + b.avg, 0) / data.length))}%` }} />
                          </div>
                          <p className="text-text-muted text-[0.65rem] mt-2">{data.length} data points</p>
                        </>
                      ) : <p className="text-text-muted text-sm">Tidak ada data tersedia</p>}
                    </div>
                  ))}
                </div>
              </div>
            )}
          </>
        )}
      </div>
    </AdminLayout>
  )
}
