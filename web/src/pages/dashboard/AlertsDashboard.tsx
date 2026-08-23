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

interface Thresholds {
  [key: string]: {
    warning: number
    critical: number
  }
}

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

  useEffect(() => {
    fetchAlerts()
  }, [fetchAlerts])

  useEffect(() => {
    if (!autoRefresh) return
    const interval = setInterval(fetchAlerts, 15 * 1000) // 15 seconds
    return () => clearInterval(interval)
  }, [autoRefresh, fetchAlerts])

  const filteredAlerts = alerts.filter(alert => {
    if (filter === 'all') return true
    if (filter === 'active') return alert.status === 'active'
    if (filter === 'critical') return alert.severity === 'critical' && alert.status === 'active'
    if (filter === 'warning') return alert.severity === 'warning' && alert.status === 'active'
    return true
  })

  const getSeverityColor = (severity: string) => {
    switch (severity) {
      case 'critical': return 'bg-red-500/20 text-red-500 border-red-500/30'
      case 'warning': return 'bg-yellow-500/20 text-yellow-500 border-yellow-500/30'
      case 'info': return 'bg-green-500/20 text-green-500 border-green-500/30'
      default: return 'bg-gray-500/20 text-gray-500 border-gray-500/30'
    }
  }

  const getSeverityIcon = (severity: string) => {
    switch (severity) {
      case 'critical': return '🔴'
      case 'warning': return '🟡'
      case 'info': return '🟢'
      default: return '⚪'
    }
  }

  const getStatusColor = (status: string) => {
    return status === 'active' 
      ? 'bg-red-500/10 text-red-500' 
      : 'bg-green-500/10 text-green-500'
  }

  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp)
    const now = new Date()
    const diffMs = now.getTime() - date.getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins}m ago`
    if (diffHours < 24) return `${diffHours}h ago`
    return `${diffDays}d ago`
  }

  const clearHistory = async () => {
    if (!confirm('Are you sure you want to clear alert history?')) return
    try {
      await api.delete('/admin/performance/alerts')
      fetchAlerts()
    } catch (err) {
      console.error('Failed to clear alerts:', err)
    }
  }

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading alerts...</div>
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
            <h1 className="text-2xl font-bold text-text-primary">Performance Alerts</h1>
            <p className="text-text-secondary">Real-time system monitoring and alerts</p>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <label className="text-sm text-text-secondary">Auto-refresh:</label>
              <button
                onClick={() => setAutoRefresh(!autoRefresh)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  autoRefresh
                    ? 'bg-success/20 text-success'
                    : 'bg-surface-light text-text-secondary hover:text-text-primary'
                }`}
              >
                {autoRefresh ? 'ON' : 'OFF'}
              </button>
            </div>
            <button
              onClick={fetchAlerts}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              🔄 Refresh
            </button>
            <button
              onClick={clearHistory}
              className="px-4 py-2 bg-surface-light text-text-secondary rounded-lg hover:bg-surface transition-colors"
            >
              🗑️ Clear History
            </button>
          </div>
        </div>

        {lastUpdated && (
          <div className="text-sm text-text-muted">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </div>
        )}

        {/* Alert Statistics */}
        {stats && (
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Total Alerts</p>
              <p className="text-2xl font-bold text-text-primary">{stats.total}</p>
            </div>
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Active</p>
              <p className="text-2xl font-bold text-red-500">{stats.active}</p>
            </div>
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Critical</p>
              <p className="text-2xl font-bold text-red-500">{stats.critical}</p>
            </div>
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Warning</p>
              <p className="text-2xl font-bold text-yellow-500">{stats.warning}</p>
            </div>
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Last 24h</p>
              <p className="text-2xl font-bold text-text-primary">{stats.last_24h}</p>
            </div>
            <div className="bg-surface border border-border rounded-xl p-4">
              <p className="text-text-muted text-sm">Last 7d</p>
              <p className="text-2xl font-bold text-text-primary">{stats.last_7d}</p>
            </div>
          </div>
        )}

        {/* Filters */}
        <div className="flex items-center gap-2">
          <span className="text-text-secondary text-sm">Filter:</span>
          {(['all', 'active', 'critical', 'warning'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                filter === f
                  ? 'bg-accent text-primary'
                  : 'bg-surface-light text-text-secondary hover:text-text-primary'
              }`}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>

        {/* Error message */}
        {error && (
          <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-500">
            {error}
          </div>
        )}

        {/* Alerts List */}
        <div className="bg-surface border border-border rounded-xl overflow-hidden">
          <div className="p-4 border-b border-border">
            <h2 className="text-lg font-semibold text-text-primary">
              Alert History ({filteredAlerts.length})
            </h2>
          </div>
          
          {filteredAlerts.length === 0 ? (
            <div className="p-8 text-center text-text-muted">
              <span className="text-4xl block mb-4">🔔</span>
              <p>No alerts found</p>
            </div>
          ) : (
            <div className="divide-y divide-border">
              {filteredAlerts.map((alert) => (
                <div
                  key={alert.id}
                  className={`p-4 hover:bg-surface-light transition-colors ${
                    alert.status === 'active' ? 'border-l-4' : ''
                  } ${
                    alert.severity === 'critical' ? 'border-l-red-500' :
                    alert.severity === 'warning' ? 'border-l-yellow-500' :
                    'border-l-green-500'
                  }`}
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-3">
                      <span className="text-xl">{getSeverityIcon(alert.severity)}</span>
                      <div className="flex-1">
                        <p className="text-text-primary font-medium">{alert.message}</p>
                        <div className="flex items-center gap-4 mt-1 text-sm text-text-muted">
                          <span>Metric: {alert.metric}</span>
                          <span>Value: {alert.value}</span>
                          <span>Threshold: {alert.threshold}</span>
                          <span>{formatTimestamp(alert.timestamp)}</span>
                        </div>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`px-2 py-1 text-xs rounded ${getSeverityColor(alert.severity)}`}>
                        {alert.severity}
                      </span>
                      <span className={`px-2 py-1 text-xs rounded ${getStatusColor(alert.status)}`}>
                        {alert.status}
                      </span>
                    </div>
                  </div>
                  {alert.resolved_at && (
                    <div className="mt-2 ml-8 text-sm text-green-500">
                      ✅ Resolved at {new Date(alert.resolved_at).toLocaleString()}
                    </div>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Thresholds Configuration */}
        {Object.keys(thresholds).length > 0 && (
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">📊 Alert Thresholds</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(thresholds).map(([metric, threshold]) => (
                <div key={metric} className="p-4 bg-surface-light rounded-lg">
                  <h3 className="text-text-primary font-medium capitalize">
                    {metric.replace('_', ' ')}
                  </h3>
                  <div className="mt-2 space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-yellow-500">Warning:</span>
                      <span className="text-text-primary">≥ {threshold.warning}%</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-red-500">Critical:</span>
                      <span className="text-text-primary">≥ {threshold.critical}%</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Alerts by Metric */}
        {stats && Object.keys(stats.by_metric).length > 0 && (
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">📈 Alerts by Metric</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {Object.entries(stats.by_metric).map(([metric, data]) => (
                <div key={metric} className="p-4 bg-surface-light rounded-lg">
                  <h3 className="text-text-primary font-medium capitalize">
                    {metric.replace('_', ' ')}
                  </h3>
                  <div className="mt-2 space-y-1 text-sm">
                    <div className="flex justify-between">
                      <span className="text-text-muted">Total:</span>
                      <span className="text-text-primary">{data.total}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-red-500">Critical:</span>
                      <span className="text-text-primary">{data.critical}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-yellow-500">Warning:</span>
                      <span className="text-text-primary">{data.warning}</span>
                    </div>
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
