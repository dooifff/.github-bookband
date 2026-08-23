import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface ServerMetrics {
  cpu_usage: number
  memory: {
    used: string
    total: string
    percentage: number
    php_limit: string
  }
  disk: {
    used: string
    total: string
    free: string
    percentage: number
  }
  uptime: string
  php_version: string
  laravel_version: string
  environment: string
}

interface DatabaseMetrics {
  driver: string
  database: string
  query_time_ms: number
  table_count: number
  size: string
  status: string
}

interface ApplicationMetrics {
  requests: {
    total: number
    errors: number
    error_rate: number
  }
  response_time: {
    average_ms: number
  }
  active_users: number
  process: {
    pid: number
    memory_peak: string
  }
}

interface PerformanceAlert {
  type: 'warning' | 'critical' | 'info'
  message: string
  metric: string
  value: number
  threshold: number
  timestamp: string
}

interface PerformanceData {
  server: ServerMetrics
  database: DatabaseMetrics
  application: ApplicationMetrics
  response_time_ms: number
  timestamp: string
}

export default function PerformanceDashboard() {
  const [metrics, setMetrics] = useState<PerformanceData | null>(null)
  const [alerts, setAlerts] = useState<PerformanceAlert[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [autoRefresh, setAutoRefresh] = useState(true)
  const [refreshInterval, setRefreshInterval] = useState(30)
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null)

  const fetchMetrics = useCallback(async () => {
    try {
      const [metricsRes, alertsRes] = await Promise.all([
        api.get('/admin/performance'),
        api.get('/admin/performance/alerts'),
      ])

      setMetrics(metricsRes.data.data)
      setAlerts(alertsRes.data.data.alerts)
      setLastUpdated(new Date())
      setError('')
    } catch (err: any) {
      console.error('Failed to fetch metrics:', err)
      setError(err.response?.data?.message || 'Failed to load performance metrics')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchMetrics()
  }, [fetchMetrics])

  useEffect(() => {
    if (!autoRefresh) return

    const interval = setInterval(fetchMetrics, refreshInterval * 1000)
    return () => clearInterval(interval)
  }, [autoRefresh, refreshInterval, fetchMetrics])

  const getStatusColor = (value: number, thresholds: { warning: number; critical: number }) => {
    if (value >= thresholds.critical) return 'text-red-500'
    if (value >= thresholds.warning) return 'text-yellow-500'
    return 'text-green-500'
  }

  const getBarColor = (value: number, thresholds: { warning: number; critical: number }) => {
    if (value >= thresholds.critical) return 'bg-red-500'
    if (value >= thresholds.warning) return 'bg-yellow-500'
    return 'bg-green-500'
  }

  const CircularProgress = ({ value, label, color }: { value: number; label: string; color: string }) => {
    const circumference = 2 * Math.PI * 45
    const strokeDashoffset = circumference - (value / 100) * circumference

    return (
      <div className="flex flex-col items-center">
        <div className="relative w-28 h-28">
          <svg className="w-28 h-28 transform -rotate-90">
            <circle
              cx="56"
              cy="56"
              r="45"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              className="text-surface-light"
            />
            <circle
              cx="56"
              cy="56"
              r="45"
              stroke="currentColor"
              strokeWidth="8"
              fill="none"
              strokeDasharray={circumference}
              strokeDashoffset={strokeDashoffset}
              className={color}
              strokeLinecap="round"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-xl font-bold text-text-primary">{Math.round(value)}%</span>
          </div>
        </div>
        <span className="mt-2 text-sm text-text-secondary">{label}</span>
      </div>
    )
  }

  const MetricCard = ({ title, value, icon, subtitle }: { title: string; value: string | number; icon: string; subtitle?: string }) => (
    <div className="bg-surface border border-border rounded-xl p-5 hover:shadow-lg transition-shadow">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-text-muted text-sm">{title}</p>
          <p className="text-2xl font-bold text-text-primary mt-1">{value}</p>
          {subtitle && <p className="text-text-muted text-xs mt-1">{subtitle}</p>}
        </div>
        <div className="w-12 h-12 rounded-lg flex items-center justify-center text-2xl bg-accent/10">
          {icon}
        </div>
      </div>
    </div>
  )

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading performance metrics...</div>
        </div>
      </AdminLayout>
    )
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <p className="text-error mb-4">{error}</p>
            <button
              onClick={fetchMetrics}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              Retry
            </button>
          </div>
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
            <h1 className="text-2xl font-bold text-text-primary">Performance Dashboard</h1>
            <p className="text-text-secondary">Real-time system metrics and monitoring</p>
          </div>
          <div className="flex items-center gap-4">
            {/* Auto-refresh toggle */}
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
            {/* Refresh interval */}
            {autoRefresh && (
              <select
                value={refreshInterval}
                onChange={(e) => setRefreshInterval(Number(e.target.value))}
                className="px-3 py-1.5 bg-surface border border-border rounded-lg text-sm text-text-primary"
              >
                <option value={10}>10s</option>
                <option value={30}>30s</option>
                <option value={60}>60s</option>
              </select>
            )}
            {/* Manual refresh */}
            <button
              onClick={fetchMetrics}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              🔄 Refresh
            </button>
          </div>
        </div>

        {/* Last Updated */}
        {lastUpdated && (
          <div className="text-sm text-text-muted">
            Last updated: {lastUpdated.toLocaleTimeString()}
          </div>
        )}

        {/* Alerts */}
        {alerts.length > 0 && (
          <div className="space-y-2">
            {alerts.map((alert, index) => (
              <div
                key={index}
                className={`p-4 rounded-lg border ${
                  alert.type === 'critical'
                    ? 'bg-red-500/10 border-red-500/30 text-red-500'
                    : 'bg-yellow-500/10 border-yellow-500/30 text-yellow-500'
                }`}
              >
                <div className="flex items-center gap-2">
                  <span>{alert.type === 'critical' ? '🔴' : '🟡'}</span>
                  <span className="font-medium">{alert.message}</span>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <MetricCard
            title="CPU Usage"
            value={`${metrics?.server.cpu_usage || 0}%`}
            icon="🖥️"
            subtitle={metrics?.server.uptime}
          />
          <MetricCard
            title="Memory Usage"
            value={`${metrics?.server.memory.percentage || 0}%`}
            icon="💾"
            subtitle={`${metrics?.server.memory.used} / ${metrics?.server.memory.total}`}
          />
          <MetricCard
            title="Disk Usage"
            value={`${metrics?.server.disk.percentage || 0}%`}
            icon="💿"
            subtitle={`${metrics?.server.disk.used} / ${metrics?.server.disk.total}`}
          />
          <MetricCard
            title="Response Time"
            value={`${metrics?.response_time_ms || 0}ms`}
            icon="⚡"
            subtitle="API response time"
          />
        </div>

        {/* Circular Gauges */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-6">System Resources</h2>
          <div className="flex justify-around flex-wrap gap-8">
            <CircularProgress
              value={metrics?.server.cpu_usage || 0}
              label="CPU"
              color={getBarColor(metrics?.server.cpu_usage || 0, { warning: 70, critical: 90 })}
            />
            <CircularProgress
              value={metrics?.server.memory.percentage || 0}
              label="Memory"
              color={getBarColor(metrics?.server.memory.percentage || 0, { warning: 70, critical: 85 })}
            />
            <CircularProgress
              value={metrics?.server.disk.percentage || 0}
              label="Disk"
              color={getBarColor(metrics?.server.disk.percentage || 0, { warning: 80, critical: 90 })}
            />
          </div>
        </div>

        {/* Detailed Metrics Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Server Details */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">🖥️ Server Information</h2>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">PHP Version</span>
                <span className="text-text-primary font-medium">{metrics?.server.php_version}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Laravel Version</span>
                <span className="text-text-primary font-medium">{metrics?.server.laravel_version}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Environment</span>
                <span className={`px-2 py-1 text-xs rounded ${
                  metrics?.server.environment === 'production' 
                    ? 'bg-success/20 text-success' 
                    : 'bg-warning/20 text-warning'
                }`}>
                  {metrics?.server.environment}
                </span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">PHP Memory Limit</span>
                <span className="text-text-primary font-medium">{metrics?.server.memory.php_limit}</span>
              </div>
              <div className="flex justify-between py-2">
                <span className="text-text-secondary">Disk Free Space</span>
                <span className="text-text-primary font-medium">{metrics?.server.disk.free}</span>
              </div>
            </div>
          </div>

          {/* Database Details */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">🗄️ Database Performance</h2>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Driver</span>
                <span className="text-text-primary font-medium uppercase">{metrics?.database.driver}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Database Name</span>
                <span className="text-text-primary font-medium">{metrics?.database.database}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Query Time</span>
                <span className={`font-medium ${getStatusColor(metrics?.database.query_time_ms || 0, { warning: 100, critical: 500 })}`}>
                  {metrics?.database.query_time_ms}ms
                </span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Table Count</span>
                <span className="text-text-primary font-medium">{metrics?.database.table_count}</span>
              </div>
              <div className="flex justify-between py-2">
                <span className="text-text-secondary">Database Size</span>
                <span className="text-text-primary font-medium">{metrics?.database.size}</span>
              </div>
            </div>
          </div>

          {/* Application Metrics */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">📊 Application Metrics</h2>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Total Requests</span>
                <span className="text-text-primary font-medium">{metrics?.application.requests.total.toLocaleString()}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Error Rate</span>
                <span className={`font-medium ${getStatusColor(metrics?.application.requests.error_rate || 0, { warning: 1, critical: 5 })}`}>
                  {metrics?.application.requests.error_rate}%
                </span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Avg Response Time</span>
                <span className="text-text-primary font-medium">{metrics?.application.response_time.average_ms}ms</span>
              </div>
              <div className="flex justify-between py-2">
                <span className="text-text-secondary">Active Users</span>
                <span className="text-text-primary font-medium">{metrics?.application.active_users}</span>
              </div>
            </div>
          </div>

          {/* Process Info */}
          <div className="bg-surface border border-border rounded-xl p-6">
            <h2 className="text-lg font-semibold text-text-primary mb-4">⚙️ Process Information</h2>
            <div className="space-y-3">
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Process ID</span>
                <span className="text-text-primary font-medium">{metrics?.application.process.pid}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Memory Peak</span>
                <span className="text-text-primary font-medium">{metrics?.application.process.memory_peak}</span>
              </div>
              <div className="flex justify-between py-2 border-b border-border">
                <span className="text-text-secondary">Response Time</span>
                <span className="text-text-primary font-medium">{metrics?.response_time_ms}ms</span>
              </div>
              <div className="flex justify-between py-2">
                <span className="text-text-secondary">Timestamp</span>
                <span className="text-text-primary font-medium text-sm">
                  {new Date(metrics?.timestamp || '').toLocaleString()}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Quick Actions */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">🔧 Quick Actions</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <button
              onClick={fetchMetrics}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">🔄</span>
              <span className="text-text-primary font-medium">Refresh Metrics</span>
            </button>
            <button
              onClick={() => window.open('/api/v1/admin/performance/history?hours=24', '_blank')}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">📈</span>
              <span className="text-text-primary font-medium">View History</span>
            </button>
            <button
              onClick={() => window.open('/api/v1/admin/performance/alerts', '_blank')}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">🔔</span>
              <span className="text-text-primary font-medium">Check Alerts</span>
            </button>
            <button
              onClick={() => window.open('/api/v1/admin/performance/realtime', '_blank')}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">⚡</span>
              <span className="text-text-primary font-medium">Real-time Data</span>
            </button>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
