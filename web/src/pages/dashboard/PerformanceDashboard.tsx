import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface ServerMetrics {
  cpu_usage: number
  memory: { used: string; total: string; percentage: number; php_limit: string }
  disk: { used: string; total: string; free: string; percentage: number }
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
  requests: { total: number; errors: number; error_rate: number }
  response_time: { average_ms: number }
  active_users: number
  process: { pid: number; memory_peak: string }
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

function getBarColor(value: number, thresholds: { warning: number; critical: number }) {
  if (value >= thresholds.critical) return 'stroke-red-500'
  if (value >= thresholds.warning) return 'stroke-yellow-500'
  return 'stroke-success'
}

function CircularProgress({ value, label, color }: { value: number; label: string; color: string }) {
  const circumference = 2 * Math.PI * 45
  const strokeDashoffset = circumference - (value / 100) * circumference
  return (
    <div className="flex flex-col items-center">
      <div className="relative w-28 h-28">
        <svg className="w-28 h-28 transform -rotate-90">
          <circle cx="56" cy="56" r="45" strokeWidth="6" fill="none" className="stroke-surface-elevated" />
          <circle cx="56" cy="56" r="45" strokeWidth="6" fill="none" strokeDasharray={circumference} strokeDashoffset={strokeDashoffset} className={`${color} transition-all duration-700`} strokeLinecap="round" />
        </svg>
        <div className="absolute inset-0 flex items-center justify-center">
          <span className="text-xl font-bold text-text-primary">{Math.round(value)}%</span>
        </div>
      </div>
      <span className="mt-2 text-xs text-text-secondary font-medium">{label}</span>
    </div>
  )
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

  useEffect(() => { fetchMetrics() }, [fetchMetrics])

  useEffect(() => {
    if (!autoRefresh) return
    const interval = setInterval(fetchMetrics, refreshInterval * 1000)
    return () => clearInterval(interval)
  }, [autoRefresh, refreshInterval, fetchMetrics])

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="flex flex-col items-center gap-4">
            <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
            <p className="text-text-muted text-sm">Memuat metrik performa...</p>
          </div>
        </div>
      </AdminLayout>
    )
  }

  if (error) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <p className="text-danger mb-4">{error}</p>
            <button onClick={fetchMetrics} className="btn-gold text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between animate-fade-in-up">
          <div>
            <h1 className="text-2xl font-bold text-text-primary tracking-tight">Dasbor Performa</h1>
            <p className="text-text-secondary mt-1 text-sm">Metrik dan pemantauan sistem secara real-time</p>
          </div>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-2">
              <label className="text-text-muted text-xs">Perbarui otomatis</label>
              <button onClick={() => setAutoRefresh(!autoRefresh)} className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${autoRefresh ? 'bg-success/15 text-success border border-success/20' : 'bg-surface-lighter text-text-muted border border-border'}`}>
                {autoRefresh ? 'ON' : 'OFF'}
              </button>
            </div>
            {autoRefresh && (
              <select value={refreshInterval} onChange={(e) => setRefreshInterval(Number(e.target.value))} className="select-luxury text-xs py-1.5">
                <option value={10}>10s</option>
                <option value={30}>30s</option>
                <option value={60}>60s</option>
              </select>
            )}
            <button onClick={fetchMetrics} className="btn-gold text-xs py-1.5 px-3">🔄 Refresh</button>
          </div>
        </div>

        {lastUpdated && <p className="text-text-muted text-xs animate-fade-in">Terakhir diperbarui: {lastUpdated.toLocaleTimeString()}</p>}

        {/* Alerts */}
        {alerts.length > 0 && (
          <div className="space-y-2 animate-fade-in">
            {alerts.map((alert, index) => (
              <div key={index} className={`p-4 rounded-xl border text-sm ${
                alert.type === 'critical' ? 'bg-danger/8 border-danger/20 text-danger' : 'bg-warning/8 border-warning/20 text-warning'
              }`}>
                <span className="font-medium">{alert.type === 'critical' ? '🔴' : '🟡'} {alert.message}</span>
              </div>
            ))}
          </div>
        )}

        {/* Summary Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            { title: 'Penggunaan CPU', value: `${metrics?.server.cpu_usage || 0}%`, icon: '🖥️', subtitle: metrics?.server.uptime, accent: (metrics?.server.cpu_usage ?? 0) >= 90 ? 'text-danger' : (metrics?.server.cpu_usage ?? 0) >= 70 ? 'text-warning' : 'text-accent' },
            { title: 'Memori', value: `${metrics?.server.memory.percentage || 0}%`, icon: '💾', subtitle: `${metrics?.server.memory.used} / ${metrics?.server.memory.total}`, accent: (metrics?.server.memory.percentage ?? 0) >= 85 ? 'text-danger' : (metrics?.server.memory.percentage ?? 0) >= 70 ? 'text-warning' : 'text-accent' },
            { title: 'Disk', value: `${metrics?.server.disk.percentage || 0}%`, icon: '💿', subtitle: `${metrics?.server.disk.used} / ${metrics?.server.disk.total}`, accent: (metrics?.server.disk.percentage ?? 0) >= 90 ? 'text-danger' : (metrics?.server.disk.percentage ?? 0) >= 80 ? 'text-warning' : 'text-accent' },
            { title: 'Waktu Respons', value: `${metrics?.response_time_ms || 0}ms`, icon: '⚡', subtitle: 'Respon API', accent: 'text-accent' },
          ].map((card, i) => (
            <div key={card.title} className={`card-luxury p-3 border-l-2 border-l-accent/40 animate-fade-in-up stagger-${i + 1}`}>
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-text-secondary text-xs font-medium tracking-wide uppercase">{card.title}</p>
                  <p className={`text-2xl font-bold mt-2 tracking-tight ${card.accent}`}>{card.value}</p>
                  {card.subtitle && <p className="text-text-secondary text-xs mt-1.5">{card.subtitle}</p>}
                </div>
                <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent/15 to-accent/5 border border-accent/10 flex items-center justify-center text-lg">{card.icon}</div>
              </div>
            </div>
          ))}
        </div>

        {/* Circular Gauges */}
        <div className="card-luxury p-4 animate-fade-in-up stagger-5">            <h2 className="text-sm font-semibold text-text-primary mb-3 flex items-center gap-2"><span className="text-accent">⚙</span> Sumber Daya Sistem</h2>
          <div className="flex justify-around flex-wrap gap-6">
            <CircularProgress value={metrics?.server.cpu_usage || 0} label="CPU" color={getBarColor(metrics?.server.cpu_usage || 0, { warning: 70, critical: 90 })} />
            <CircularProgress value={metrics?.server.memory.percentage || 0} label="Memory" color={getBarColor(metrics?.server.memory.percentage || 0, { warning: 70, critical: 85 })} />
            <CircularProgress value={metrics?.server.disk.percentage || 0} label="Disk" color={getBarColor(metrics?.server.disk.percentage || 0, { warning: 80, critical: 90 })} />
          </div>
        </div>

        {/* Details Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {/* Server */}
          <div className="card-luxury p-4 animate-fade-in-up stagger-6">
            <h2 className="text-sm font-semibold text-text-primary mb-2 flex items-center gap-2">🖥️ Server</h2>
            <div className="space-y-0">
              {[
                { label: 'Versi PHP', value: metrics?.server.php_version },
                { label: 'Laravel', value: metrics?.server.laravel_version },
                { label: 'Lingkungan', value: metrics?.server.environment },
                { label: 'Batas PHP', value: metrics?.server.memory.php_limit },
                { label: 'Ruang Disk', value: metrics?.server.disk.free },
              ].map((item, i) => (
                <div key={item.label} className={`flex justify-between py-2 ${i < 4 ? 'border-b border-border-light/40' : ''}`}>
                  <span className="text-text-secondary text-sm">{item.label}</span>
                  <span className="text-text-primary text-sm font-medium">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Database */}
          <div className="card-luxury p-4 animate-fade-in-up stagger-7">
            <h2 className="text-sm font-semibold text-text-primary mb-2 flex items-center gap-2">🗄️ Database</h2>
            <div className="space-y-0">
              {[
                { label: 'Driver', value: metrics?.database.driver?.toUpperCase() },
                { label: 'Nama', value: metrics?.database.database },
                { label: 'Waktu Kueri', value: `${metrics?.database.query_time_ms}ms` },
                { label: 'Tabel', value: metrics?.database.table_count },
                { label: 'Ukuran', value: metrics?.database.size },
              ].map((item, i) => (
                <div key={item.label} className={`flex justify-between py-2 ${i < 4 ? 'border-b border-border-light/40' : ''}`}>
                  <span className="text-text-secondary text-sm">{item.label}</span>
                  <span className="text-text-primary text-sm font-medium">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Application */}
          <div className="card-luxury p-4 animate-fade-in-up stagger-6">
            <h2 className="text-sm font-semibold text-text-primary mb-2 flex items-center gap-2">📊 Aplikasi</h2>
            <div className="space-y-0">
              {[
                { label: 'Total Permintaan', value: metrics?.application.requests.total.toLocaleString() },
                { label: 'Tingkat Kesalahan', value: `${metrics?.application.requests.error_rate}%` },
                { label: 'Rata-rata Respons', value: `${metrics?.application.response_time.average_ms}ms` },
                { label: 'Pengguna Aktif', value: metrics?.application.active_users },
              ].map((item, i) => (
                <div key={item.label} className={`flex justify-between py-2 ${i < 3 ? 'border-b border-border-light/40' : ''}`}>
                  <span className="text-text-secondary text-sm">{item.label}</span>
                  <span className="text-text-primary text-sm font-medium">{item.value}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Process */}
          <div className="card-luxury p-4 animate-fade-in-up stagger-7">
            <h2 className="text-sm font-semibold text-text-primary mb-2 flex items-center gap-2">⚙️ Proses</h2>
            <div className="space-y-0">
              {[
                { label: 'PID', value: metrics?.application.process.pid },
                { label: 'Memory Peak', value: metrics?.application.process.memory_peak },
                { label: 'Database', value: metrics?.database.status },
              ].map((item, i) => (
                <div key={item.label} className={`flex justify-between py-2 ${i < 2 ? 'border-b border-border-light/40' : ''}`}>
                  <span className="text-text-secondary text-sm">{item.label}</span>
                  <span className="text-text-primary text-sm font-medium">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
