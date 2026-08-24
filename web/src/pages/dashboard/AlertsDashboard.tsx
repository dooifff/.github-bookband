import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Alert {
  id: string
  metric: string
  severity: 'critical' | 'warning' | 'info'
  message: string
  value: number
  threshold: number
  timestamp: string
  status: 'active' | 'resolved'
  resolved_at?: string
}

interface AlertStats {
  total: number
  active: number
  resolved: number
  critical: number
  warning: number
  by_metric: Record<string, { total: number; critical: number; warning: number }>
  last_24h: number
  last_7d: number
}

interface Thresholds { [key: string]: { warning: number; critical: number } }

export default function AlertsDashboard() {
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [stats, setStats] = useState<AlertStats | null>(null)
  const [thresholds, setThresholds] = useState<Thresholds>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [filter, setFilter] = useState<'all' | 'active' | 'critical' | 'warning'>('all')
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)

  const fetchAlerts = useCallback(async () => {
    try {
      const [alertsRes, statsRes, thresholdsRes] = await Promise.all([
        api.get('/admin/performance/alerts', { params: { per_page: 100 } }),
        api.get('/admin/performance/alerts/stats'),
        api.get('/admin/performance/alerts/thresholds'),
      ])
      setAlerts(alertsRes.data.data)
      setStats(statsRes.data.data)
      setThresholds(thresholdsRes.data.data)
      setLastUpdated(new Date())
      setError('')
    } catch (err: any) {
      console.error('Failed to fetch alerts:', err)
      setError(err.response?.data?.message || 'Failed to load alerts')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchAlerts() }, [fetchAlerts])
  useEffect(() => {
    if (!autoRefresh) return
    const interval = setInterval(fetchAlerts, 15000)
    return () => clearInterval(interval)
  }, [autoRefresh, fetchAlerts])

  const filteredAlerts = alerts.filter(alert => {
    if (filter === 'all') return true
    if (filter === 'active') return alert.status === 'active'
    if (filter === 'critical') return alert.severity === 'critical' && alert.status === 'active'
    if (filter === 'warning') return alert.severity === 'warning' && alert.status === 'active'
    return true
  })

  const getSeverityBadge = (severity: string) => {
    const styles: Record<string, string> = {
      critical: 'bg-danger/10 text-danger border border-danger/20',
      warning: 'bg-warning/10 text-warning border border-warning/20',
      info: 'bg-success/10 text-success border border-success/20',
    }
    return styles[severity] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const formatTimestamp = (timestamp: string) => {
    const diffMs = new Date().getTime() - new Date(timestamp).getTime()
    const mins = Math.floor(diffMs / 60000)
    const hours = Math.floor(diffMs / 3600000)
    const days = Math.floor(diffMs / 86400000)
    if (mins < 1) return 'Just now'
    if (mins < 60) return `${mins}m ago`
    if (hours < 24) return `${hours}h ago`
    return `${days}d ago`
  }

  const clearHistory = async () => {
    if (!confirm('Are you sure you want to clear alert history?')) return
    try { await api.delete('/admin/performance/alerts'); fetchAlerts() } catch (err) { console.error('Failed to clear:', err) }
  }

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Loading alerts...</p>
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
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Performance Alerts</h1>
            <p className="text-text-secondary mt-1 text-sm">Real-time system monitoring and alerts</p>
          </div>
          <div className="flex items-center gap-3">
            <div className="flex items-center gap-2">
              <label className="text-text-muted text-xs">Auto-refresh</label>
              <button onClick={() => setAutoRefresh(!autoRefresh)} className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${autoRefresh ? 'bg-success/15 text-success border border-success/20' : 'bg-surface-lighter text-text-muted border border-border'}`}>
                {autoRefresh ? 'ON' : 'OFF'}
              </button>
            </div>
            <button onClick={fetchAlerts} className="btn-gold text-xs py-1.5 px-3">🔄 Refresh</button>
            <button onClick={clearHistory} className="btn-glass text-xs py-1.5 px-3">🗑️ Clear</button>
          </div>
        </div>

        {lastUpdated && <p className="text-text-muted text-xs animate-fade-in">Last updated: {lastUpdated.toLocaleTimeString()}</p>}

        {/* Stats */}
        {stats && (
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            {[
              { label: 'Total', value: stats.total, color: 'text-text-primary' },
              { label: 'Active', value: stats.active, color: 'text-danger' },
              { label: 'Critical', value: stats.critical, color: 'text-danger' },
              { label: 'Warning', value: stats.warning, color: 'text-warning' },
              { label: 'Last 24h', value: stats.last_24h, color: 'text-text-primary' },
              { label: 'Last 7d', value: stats.last_7d, color: 'text-text-primary' },
            ].map((stat, i) => (
              <div key={stat.label} className={`card-luxury p-4 animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                <p className="text-text-muted text-[0.65rem] font-medium uppercase tracking-wide">{stat.label}</p>
                <p className={`text-xl font-bold mt-1 ${stat.color}`}>{stat.value}</p>
              </div>
            ))}
          </div>
        )}

        {/* Filters */}
        <div className="flex items-center gap-2 animate-fade-in-up">
          {(['all', 'active', 'critical', 'warning'] as const).map((f) => (
            <button key={f} onClick={() => setFilter(f)} className={`px-4 py-1.5 rounded-xl text-xs font-medium transition-all ${
              filter === f ? 'bg-accent text-primary shadow-sm shadow-accent/20' : 'bg-surface-light border border-border text-text-secondary hover:text-text-primary'
            }`}>{f.charAt(0).toUpperCase() + f.slice(1)}</button>
          ))}
        </div>

        {error && <div className="p-4 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">{error}</div>}

        {/* Alert List */}
        <div className="card-luxury overflow-hidden animate-fade-in-up">
          <div className="px-6 py-4 border-b border-border/40">
            <h2 className="text-base font-semibold text-text-primary">Alert History ({filteredAlerts.length})</h2>
          </div>
          {filteredAlerts.length === 0 ? (
            <div className="p-12 text-center text-text-muted">
              <span className="text-4xl block mb-4">🔔</span>
              <p className="text-sm">No alerts found</p>
            </div>
          ) : (
            <div className="divide-y divide-border/30">
              {filteredAlerts.map((alert) => (
                <div key={alert.id} className={`px-6 py-4 hover:bg-surface-lighter/20 transition-colors ${alert.status === 'active' ? 'border-l-2' : ''} ${
                  alert.severity === 'critical' ? 'border-l-danger' : alert.severity === 'warning' ? 'border-l-warning' : 'border-l-success'
                }`}>
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1">
                      <p className="text-text-primary text-sm font-medium">{alert.message}</p>
                      <div className="flex items-center gap-4 mt-1.5 text-xs text-text-muted">
                        <span>Metric: {alert.metric}</span>
                        <span>Value: {alert.value}</span>
                        <span>Threshold: {alert.threshold}</span>
                        <span>{formatTimestamp(alert.timestamp)}</span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`badge ${getSeverityBadge(alert.severity)}`}>{alert.severity}</span>
                      <span className={`badge ${alert.status === 'active' ? 'bg-danger/10 text-danger border border-danger/20' : 'bg-success/10 text-success border border-success/20'}`}>{alert.status}</span>
                    </div>
                  </div>
                  {alert.resolved_at && (
                    <p className="text-success text-xs mt-2 ml-4">✅ Resolved at {new Date(alert.resolved_at).toLocaleString()}</p>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Thresholds */}
        {Object.keys(thresholds).length > 0 && (
          <div className="card-luxury p-6 animate-fade-in-up">
            <h2 className="text-base font-semibold text-text-primary mb-5">📊 Alert Thresholds</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(thresholds).map(([metric, threshold]) => (
                <div key={metric} className="p-4 rounded-xl bg-surface-light/50 border border-border/30">
                  <h3 className="text-text-primary text-sm font-medium capitalize">{metric.replace('_', ' ')}</h3>
                  <div className="mt-2 space-y-1 text-xs">
                    <div className="flex justify-between"><span className="text-warning">Warning:</span><span className="text-text-primary">≥ {threshold.warning}%</span></div>
                    <div className="flex justify-between"><span className="text-danger">Critical:</span><span className="text-text-primary">≥ {threshold.critical}%</span></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* By Metric */}
        {stats && Object.keys(stats.by_metric).length > 0 && (
          <div className="card-luxury p-6 animate-fade-in-up">
            <h2 className="text-base font-semibold text-text-primary mb-5">📈 Alerts by Metric</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(stats.by_metric).map(([metric, data]) => (
                <div key={metric} className="p-4 rounded-xl bg-surface-light/50 border border-border/30">
                  <h3 className="text-text-primary text-sm font-medium capitalize">{metric.replace('_', ' ')}</h3>
                  <div className="mt-2 space-y-1 text-xs">
                    <div className="flex justify-between"><span className="text-text-muted">Total:</span><span className="text-text-primary">{data.total}</span></div>
                    <div className="flex justify-between"><span className="text-danger">Critical:</span><span className="text-text-primary">{data.critical}</span></div>
                    <div className="flex justify-between"><span className="text-warning">Warning:</span><span className="text-text-primary">{data.warning}</span></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
