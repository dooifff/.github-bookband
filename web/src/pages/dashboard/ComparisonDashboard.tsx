import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface PeriodStats {
  avg: number
  min: number
  max: number
}

interface MetricComparison {
  period1: PeriodStats
  period2: PeriodStats
  change: {
    absolute: number
    percent: number
    direction: 'increased' | 'decreased' | 'unchanged'
  }
  regression: boolean
}

interface ComparisonResult {
  period1: {
    start: string
    end: string
    stats: { count: number; avg: Record<string, number> }
  }
  period2: {
    start: string
    end: string
    stats: { count: number; avg: Record<string, number> }
  }
  comparison: Record<string, MetricComparison>
  summary: {
    has_regressions: boolean
    regression_count: number
    improvement_count: number
    regressions: Array<{ metric: string; change: number }>
    improvements: Array<{ metric: string; change: number }>
  }
}

interface TrendData {
  date: string
  avg: number
  min: number
  max: number
  count: number
}

export default function ComparisonDashboard() {
  const [comparison, setComparison] = useState<ComparisonResult | null>(null)
  const [trends, setTrends] = useState<Record<string, TrendData[]>>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  // Date range states
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
        api.post('/admin/performance/compare', {
          period1_start: period1Start,
          period1_end: period1End,
          period2_start: period2Start,
          period2_end: period2End,
        }),
        api.get('/admin/performance/compare/trend/cpu?days=30'),
        api.get('/admin/performance/compare/trend/memory?days=30'),
        api.get('/admin/performance/compare/trend/response_time?days=30'),
        api.get('/admin/performance/compare/trend/disk?days=30'),
      ])

      setComparison(compareRes.data.data)
      setTrends({
        cpu: trendRes[0].data.data.trend,
        memory: trendRes[1].data.data.trend,
        response_time: trendRes[2].data.data.trend,
        disk: trendRes[3].data.data.trend,
      })
    } catch (err: any) {
      console.error('Failed to fetch comparison:', err)
      setError(err.response?.data?.message || 'Failed to load comparison data')
    } finally {
      setLoading(false)
    }
  }, [period1Start, period1End, period2Start, period2End])

  useEffect(() => {
    fetchComparison()
  }, [fetchComparison])

  const exportReport = async (format: 'json' | 'markdown' | 'csv' | 'pdf') => {
    try {
      const response = await api.post('/admin/performance/compare/export', {
        period1_start: period1Start,
        period1_end: period1End,
        period2_start: period2Start,
        period2_end: period2End,
        format,
      }, {
        responseType: 'blob',
      })

      const url = window.URL.createObjectURL(new Blob([response.data]))
      const link = document.createElement('a')
      link.href = url
      const extension = format === 'markdown' ? 'md' : format;
      link.setAttribute('download', `performance-report.${extension}`)
      document.body.appendChild(link)
      link.click()
      link.remove()
    } catch (err) {
      console.error('Failed to export report:', err)
    }
  }

  const sendEmailReport = async () => {
    const email = prompt('Enter email address to send report:')
    if (!email) return

    try {
      await api.post('/admin/performance/email/send', {
        recipient: email,
        period1_start: period1Start,
        period1_end: period1End,
        period2_start: period2Start,
        period2_end: period2End,
        attach_pdf: true,
      })
      alert('Report sent successfully!')
    } catch (err) {
      console.error('Failed to send email:', err)
      alert('Failed to send report')
    }
  }

  const getChangeColor = (change: MetricComparison['change']) => {
    if (change.direction === 'unchanged') return 'text-text-muted'
    if (change.direction === 'decreased') return 'text-green-500'
    return change.percent > 20 ? 'text-red-500' : 'text-yellow-500'
  }

  const getChangeIcon = (change: MetricComparison['change']) => {
    if (change.direction === 'unchanged') return '→'
    if (change.direction === 'decreased') return '↓'
    return '↑'
  }

  const formatValue = (metric: string, value: number): string => {
    if (metric.includes('time') || metric === 'response_time') {
      return `${value.toFixed(1)}ms`
    }
    if (metric === 'error_rate' || metric.includes('rate')) {
      return `${value.toFixed(2)}%`
    }
    if (metric === 'requests_per_second') {
      return `${value.toFixed(0)} req/s`
    }
    return `${value.toFixed(1)}%`
  }

  if (loading && !comparison) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading comparison data...</div>
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
            <h1 className="text-2xl font-bold text-text-primary">Performance Comparison</h1>
            <p className="text-text-secondary">Compare performance metrics across time periods</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => exportReport('json')}
              className="px-3 py-1.5 bg-surface-light text-text-secondary rounded-lg hover:text-text-primary transition-colors text-sm"
            >
              📄 JSON
            </button>
            <button
              onClick={() => exportReport('markdown')}
              className="px-3 py-1.5 bg-surface-light text-text-secondary rounded-lg hover:text-text-primary transition-colors text-sm"
            >
              📝 Markdown
            </button>
            <button
              onClick={() => exportReport('csv')}
              className="px-3 py-1.5 bg-surface-light text-text-secondary rounded-lg hover:text-text-primary transition-colors text-sm"
            >
              📊 CSV
            </button>
            <button
              onClick={() => exportReport('pdf')}
              className="px-3 py-1.5 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors text-sm font-medium"
            >
              📕 PDF
            </button>
            <button
              onClick={sendEmailReport}
              className="px-3 py-1.5 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors text-sm font-medium"
            >
              📧 Email
            </button>
          </div>
        </div>

        {/* Date Range Selection */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">📅 Select Time Periods</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Period 1 */}
            <div className="p-4 bg-surface-light rounded-lg">
              <h3 className="text-text-primary font-medium mb-3">Period 1 (Recent)</h3>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-text-muted text-sm">Start Date</label>
                  <input
                    type="date"
                    value={period1Start}
                    onChange={(e) => setPeriod1Start(e.target.value)}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  />
                </div>
                <div>
                  <label className="text-text-muted text-sm">End Date</label>
                  <input
                    type="date"
                    value={period1End}
                    onChange={(e) => setPeriod1End(e.target.value)}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  />
                </div>
              </div>
            </div>

            {/* Period 2 */}
            <div className="p-4 bg-surface-light rounded-lg">
              <h3 className="text-text-primary font-medium mb-3">Period 2 (Previous)</h3>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="text-text-muted text-sm">Start Date</label>
                  <input
                    type="date"
                    value={period2Start}
                    onChange={(e) => setPeriod2Start(e.target.value)}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  />
                </div>
                <div>
                  <label className="text-text-muted text-sm">End Date</label>
                  <input
                    type="date"
                    value={period2End}
                    onChange={(e) => setPeriod2End(e.target.value)}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  />
                </div>
              </div>
            </div>
          </div>
          <div className="mt-4 flex justify-end">
            <button
              onClick={fetchComparison}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              🔄 Compare Periods
            </button>
          </div>
        </div>

        {/* Error */}
        {error && (
          <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-500">
            {error}
          </div>
        )}

        {/* Summary Cards */}
        {comparison && (
          <>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="bg-surface border border-border rounded-xl p-5">
                <p className="text-text-muted text-sm">Period 1 Snapshots</p>
                <p className="text-2xl font-bold text-text-primary">{comparison.period1.stats.count}</p>
                <p className="text-text-muted text-xs mt-1">
                  {comparison.period1.start} to {comparison.period1.end}
                </p>
              </div>
              <div className="bg-surface border border-border rounded-xl p-5">
                <p className="text-text-muted text-sm">Period 2 Snapshots</p>
                <p className="text-2xl font-bold text-text-primary">{comparison.period2.stats.count}</p>
                <p className="text-text-muted text-xs mt-1">
                  {comparison.period2.start} to {comparison.period2.end}
                </p>
              </div>
              <div className={`border rounded-xl p-5 ${comparison.summary.has_regressions ? 'bg-red-500/10 border-red-500/30' : 'bg-green-500/10 border-green-500/30'}`}>
                <p className="text-text-muted text-sm">Regressions</p>
                <p className={`text-2xl font-bold ${comparison.summary.has_regressions ? 'text-red-500' : 'text-green-500'}`}>
                  {comparison.summary.regression_count}
                </p>
              </div>
              <div className="bg-surface border border-border rounded-xl p-5">
                <p className="text-text-muted text-sm">Improvements</p>
                <p className="text-2xl font-bold text-green-500">{comparison.summary.improvement_count}</p>
              </div>
            </div>

            {/* Regressions Alert */}
            {comparison.summary.has_regressions && (
              <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg">
                <h3 className="text-red-500 font-semibold mb-2">⚠️ Performance Regressions Detected</h3>
                <ul className="list-disc list-inside text-red-500">
                  {comparison.summary.regressions.map((reg, i) => (
                    <li key={i}>{reg.metric}: +{reg.change.toFixed(1)}%</li>
                  ))}
                </ul>
              </div>
            )}

            {/* Comparison Table */}
            <div className="bg-surface border border-border rounded-xl overflow-hidden">
              <div className="p-4 border-b border-border">
                <h2 className="text-lg font-semibold text-text-primary">📊 Metric Comparison</h2>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead>
                    <tr className="bg-surface-light">
                      <th className="text-left p-4 text-text-muted font-medium">Metric</th>
                      <th className="text-right p-4 text-text-muted font-medium">Period 1 Avg</th>
                      <th className="text-right p-4 text-text-muted font-medium">Period 2 Avg</th>
                      <th className="text-right p-4 text-text-muted font-medium">Change</th>
                      <th className="text-center p-4 text-text-muted font-medium">Status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {Object.entries(comparison.comparison).map(([metric, data]) => (
                      <tr key={metric} className="border-t border-border hover:bg-surface-light">
                        <td className="p-4 text-text-primary font-medium capitalize">
                          {metric.replace(/_/g, ' ')}
                        </td>
                        <td className="p-4 text-right text-text-secondary">
                          {formatValue(metric, data.period1.avg)}
                        </td>
                        <td className="p-4 text-right text-text-secondary">
                          {formatValue(metric, data.period2.avg)}
                        </td>
                        <td className={`p-4 text-right font-medium ${getChangeColor(data.change)}`}>
                          {getChangeIcon(data.change)} {Math.abs(data.change.percent).toFixed(1)}%
                        </td>
                        <td className="p-4 text-center">
                          {data.regression ? (
                            <span className="px-2 py-1 bg-red-500/20 text-red-500 text-xs rounded">
                              Regression
                            </span>
                          ) : (
                            <span className="px-2 py-1 bg-green-500/20 text-green-500 text-xs rounded">
                              OK
                            </span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Detailed Metrics */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {Object.entries(comparison.comparison).map(([metric, data]) => (
                <div key={metric} className="bg-surface border border-border rounded-xl p-5">
                  <h3 className="text-text-primary font-semibold mb-3 capitalize">
                    {metric.replace(/_/g, ' ')}
                  </h3>
                  <div className="grid grid-cols-2 gap-4">
                    <div className="p-3 bg-surface-light rounded-lg">
                      <p className="text-text-muted text-xs">Period 1</p>
                      <p className="text-text-primary font-medium">{formatValue(metric, data.period1.avg)}</p>
                      <p className="text-text-muted text-xs">
                        Min: {formatValue(metric, data.period1.min)} / Max: {formatValue(metric, data.period1.max)}
                      </p>
                    </div>
                    <div className="p-3 bg-surface-light rounded-lg">
                      <p className="text-text-muted text-xs">Period 2</p>
                      <p className="text-text-primary font-medium">{formatValue(metric, data.period2.avg)}</p>
                      <p className="text-text-muted text-xs">
                        Min: {formatValue(metric, data.period2.min)} / Max: {formatValue(metric, data.period2.max)}
                      </p>
                    </div>
                  </div>
                  <div className="mt-3 text-center">
                    <span className={`text-lg font-bold ${getChangeColor(data.change)}`}>
                      {getChangeIcon(data.change)} {Math.abs(data.change.percent).toFixed(1)}%
                    </span>
                  </div>
                </div>
              ))}
            </div>

            {/* Trends */}
            {Object.keys(trends).length > 0 && (
              <div className="bg-surface border border-border rounded-xl p-6">
                <h2 className="text-lg font-semibold text-text-primary mb-4">📈 30-Day Trends</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {Object.entries(trends).map(([metric, data]) => (
                    <div key={metric} className="p-4 bg-surface-light rounded-lg">
                      <h3 className="text-text-primary font-medium mb-2 capitalize">
                        {metric.replace(/_/g, ' ')}
                      </h3>
                      {data.length > 0 ? (
                        <>
                          <div className="flex justify-between text-sm text-text-muted mb-2">
                            <span>Min: {formatValue(metric, Math.min(...data.map(d => d.min)))}</span>
                            <span>Avg: {formatValue(metric, data.reduce((a, b) => a + b.avg, 0) / data.length)}</span>
                            <span>Max: {formatValue(metric, Math.max(...data.map(d => d.max)))}</span>
                          </div>
                          <div className="h-2 bg-surface rounded-full overflow-hidden">
                            <div
                              className="h-full bg-accent"
                              style={{
                                width: `${Math.min(100, (data.reduce((a, b) => a + b.avg, 0) / data.length) / 100 * 100)}%`
                              }}
                            />
                          </div>
                          <p className="text-text-muted text-xs mt-2">{data.length} data points</p>
                        </>
                      ) : (
                        <p className="text-text-muted text-sm">No data available</p>
                      )}
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
