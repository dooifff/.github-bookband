import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface ScheduleSettings {
  daily: {
    enabled: boolean
    time: string
    recipients: string[]
  }
  weekly: {
    enabled: boolean
    day: string
    time: string
    recipients: string[]
  }
  monthly: {
    enabled: boolean
    day: number
    time: string
    recipients: string[]
  }
}

export default function ScheduleSettings() {
  const [settings, setSettings] = useState<ScheduleSettings>({
    daily: { enabled: false, time: '08:00', recipients: [] },
    weekly: { enabled: true, day: 'monday', time: '09:00', recipients: [] },
    monthly: { enabled: true, day: 1, time: '09:00', recipients: [] },
  })
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')
  const [newRecipient, setNewRecipient] = useState('')
  const [testingEmail, setTestingEmail] = useState(false)

  useEffect(() => {
    fetchSettings()
  }, [])

  const fetchSettings = async () => {
    try {
      const response = await api.get('/admin/performance/email/schedule')
      if (response.data.data) {
        setSettings(response.data.data)
      }
    } catch (err) {
      console.error('Failed to fetch settings:', err)
    } finally {
      setLoading(false)
    }
  }

  const saveSettings = async () => {
    setSaving(true)
    setError('')
    setSuccess('')

    try {
      // Save would go to a settings endpoint
      await api.put('/admin/settings/schedule', settings)
      setSuccess('Settings saved successfully!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save settings')
    } finally {
      setSaving(false)
    }
  }

  const addRecipient = () => {
    if (!newRecipient || !newRecipient.includes('@')) {
      setError('Please enter a valid email address')
      return
    }

    setSettings(prev => ({
      ...prev,
      weekly: {
        ...prev.weekly,
        recipients: [...prev.weekly.recipients, newRecipient],
      },
    }))
    setNewRecipient('')
  }

  const removeRecipient = (email: string) => {
    setSettings(prev => ({
      ...prev,
      weekly: {
        ...prev.weekly,
        recipients: prev.weekly.recipients.filter(r => r !== email),
      },
    }))
  }

  const testEmail = async () => {
    setTestingEmail(true)
    try {
      await api.post('/admin/performance/email/weekly')
      setSuccess('Test email sent successfully!')
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to send test email')
    } finally {
      setTestingEmail(false)
    }
  }

  const toggleSchedule = (type: 'daily' | 'weekly' | 'monthly') => {
    setSettings(prev => ({
      ...prev,
      [type]: {
        ...prev[type],
        enabled: !prev[type].enabled,
      },
    }))
  }

  const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']

  if (loading) {
    return (
      <AdminLayout>
        <div className="flex items-center justify-center h-64">
          <div className="text-accent animate-pulse">Loading settings...</div>
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
            <h1 className="text-2xl font-bold text-text-primary">Report Schedule</h1>
            <p className="text-text-secondary">Configure automated performance report delivery</p>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={testEmail}
              disabled={testingEmail}
              className="px-4 py-2 bg-surface-light text-text-secondary rounded-lg hover:text-text-primary transition-colors disabled:opacity-50"
            >
              {testingEmail ? '⏳ Sending...' : '📧 Send Test'}
            </button>
            <button
              onClick={saveSettings}
              disabled={saving}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors disabled:opacity-50"
            >
              {saving ? '💾 Saving...' : '💾 Save Settings'}
            </button>
          </div>
        </div>

        {/* Messages */}
        {error && (
          <div className="p-4 bg-red-500/10 border border-red-500/30 rounded-lg text-red-500">
            {error}
          </div>
        )}
        {success && (
          <div className="p-4 bg-green-500/10 border border-green-500/30 rounded-lg text-green-500">
            {success}
          </div>
        )}

        {/* Daily Report */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-lg font-semibold text-text-primary">📅 Daily Summary</h2>
              <p className="text-text-secondary text-sm">Receive daily performance summary</p>
            </div>
            <button
              onClick={() => toggleSchedule('daily')}
              className={`w-12 h-6 rounded-full transition-colors ${
                settings.daily.enabled ? 'bg-green-500' : 'bg-surface-light'
              }`}
            >
              <div
                className={`w-5 h-5 bg-white rounded-full shadow transform transition-transform ${
                  settings.daily.enabled ? 'translate-x-6' : 'translate-x-0.5'
                }`}
              />
            </button>
          </div>
          
          {settings.daily.enabled && (
            <div className="grid grid-cols-2 gap-4 mt-4 p-4 bg-surface-light rounded-lg">
              <div>
                <label className="text-text-muted text-sm">Send Time</label>
                <input
                  type="time"
                  value={settings.daily.time}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    daily: { ...prev.daily, time: e.target.value },
                  }))}
                  className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                />
              </div>
            </div>
          )}
        </div>

        {/* Weekly Report */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-lg font-semibold text-text-primary">📊 Weekly Report</h2>
              <p className="text-text-secondary text-sm">Detailed weekly performance comparison</p>
            </div>
            <button
              onClick={() => toggleSchedule('weekly')}
              className={`w-12 h-6 rounded-full transition-colors ${
                settings.weekly.enabled ? 'bg-green-500' : 'bg-surface-light'
              }`}
            >
              <div
                className={`w-5 h-5 bg-white rounded-full shadow transform transition-transform ${
                  settings.weekly.enabled ? 'translate-x-6' : 'translate-x-0.5'
                }`}
              />
            </button>
          </div>
          
          {settings.weekly.enabled && (
            <div className="space-y-4 mt-4 p-4 bg-surface-light rounded-lg">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-text-muted text-sm">Day of Week</label>
                  <select
                    value={settings.weekly.day}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      weekly: { ...prev.weekly, day: e.target.value },
                    }))}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  >
                    {days.map(day => (
                      <option key={day} value={day}>
                        {day.charAt(0).toUpperCase() + day.slice(1)}
                      </option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-text-muted text-sm">Send Time</label>
                  <input
                    type="time"
                    value={settings.weekly.time}
                    onChange={(e) => setSettings(prev => ({
                      ...prev,
                      weekly: { ...prev.weekly, time: e.target.value },
                    }))}
                    className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                  />
                </div>
              </div>

              {/* Recipients */}
              <div>
                <label className="text-text-muted text-sm">Recipients</label>
                <div className="flex gap-2 mt-1">
                  <input
                    type="email"
                    value={newRecipient}
                    onChange={(e) => setNewRecipient(e.target.value)}
                    placeholder="email@example.com"
                    className="flex-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                    onKeyPress={(e) => e.key === 'Enter' && addRecipient()}
                  />
                  <button
                    onClick={addRecipient}
                    className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
                  >
                    + Add
                  </button>
                </div>
                <div className="flex flex-wrap gap-2 mt-2">
                  {settings.weekly.recipients.map((email, index) => (
                    <span
                      key={index}
                      className="inline-flex items-center gap-1 px-3 py-1 bg-accent/20 text-accent rounded-full text-sm"
                    >
                      {email}
                      <button
                        onClick={() => removeRecipient(email)}
                        className="hover:text-accent-hover"
                      >
                        ×
                      </button>
                    </span>
                  ))}
                  {settings.weekly.recipients.length === 0 && (
                    <span className="text-text-muted text-sm">No recipients added</span>
                  )}
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Monthly Report */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-lg font-semibold text-text-primary">📈 Monthly Report</h2>
              <p className="text-text-secondary text-sm">Comprehensive monthly analysis with PDF</p>
            </div>
            <button
              onClick={() => toggleSchedule('monthly')}
              className={`w-12 h-6 rounded-full transition-colors ${
                settings.monthly.enabled ? 'bg-green-500' : 'bg-surface-light'
              }`}
            >
              <div
                className={`w-5 h-5 bg-white rounded-full shadow transform transition-transform ${
                  settings.monthly.enabled ? 'translate-x-6' : 'translate-x-0.5'
                }`}
              />
            </button>
          </div>
          
          {settings.monthly.enabled && (
            <div className="grid grid-cols-2 gap-4 mt-4 p-4 bg-surface-light rounded-lg">
              <div>
                <label className="text-text-muted text-sm">Day of Month</label>
                <select
                  value={settings.monthly.day}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    monthly: { ...prev.monthly, day: Number(e.target.value) },
                  }))}
                  className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                >
                  {Array.from({ length: 28 }, (_, i) => i + 1).map(day => (
                    <option key={day} value={day}>
                      {day}{day === 1 ? 'st' : day === 2 ? 'nd' : day === 3 ? 'rd' : 'th'}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="text-text-muted text-sm">Send Time</label>
                <input
                  type="time"
                  value={settings.monthly.time}
                  onChange={(e) => setSettings(prev => ({
                    ...prev,
                    monthly: { ...prev.monthly, time: e.target.value },
                  }))}
                  className="w-full mt-1 px-3 py-2 bg-surface border border-border rounded-lg text-text-primary"
                />
              </div>
            </div>
          )}
        </div>

        {/* Quick Actions */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">⚡ Quick Actions</h2>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <button
              onClick={async () => {
                await api.post('/admin/performance/email/daily', {
                  recipient: 'admin@studiobook.com'
                })
                setSuccess('Daily report sent!')
              }}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">📅</span>
              <span className="text-text-primary font-medium text-sm">Send Daily Now</span>
            </button>
            <button
              onClick={async () => {
                await api.post('/admin/performance/email/weekly')
                setSuccess('Weekly report sent!')
              }}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">📊</span>
              <span className="text-text-primary font-medium text-sm">Send Weekly Now</span>
            </button>
            <button
              onClick={async () => {
                await api.post('/admin/performance/email/monthly', {
                  recipient: 'admin@studiobook.com'
                })
                setSuccess('Monthly report sent!')
              }}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left"
            >
              <span className="text-2xl mb-2 block">📈</span>
              <span className="text-text-primary font-medium text-sm">Send Monthly Now</span>
            </button>
            <button
              onClick={testEmail}
              disabled={testingEmail}
              className="p-4 bg-surface-light border border-border rounded-lg hover:border-accent transition-colors text-left disabled:opacity-50"
            >
              <span className="text-2xl mb-2 block">📧</span>
              <span className="text-text-primary font-medium text-sm">
                {testingEmail ? 'Sending...' : 'Test Email'}
              </span>
            </button>
          </div>
        </div>

        {/* Schedule Info */}
        <div className="bg-surface border border-border rounded-xl p-6">
          <h2 className="text-lg font-semibold text-text-primary mb-4">ℹ️ Schedule Information</h2>
          <div className="space-y-3 text-sm text-text-secondary">
            <p>
              <strong>Daily Summary:</strong> Quick overview of yesterday's performance metrics.
            </p>
            <p>
              <strong>Weekly Report:</strong> Detailed comparison with the previous week, including PDF attachment.
            </p>
            <p>
              <strong>Monthly Report:</strong> Comprehensive analysis with trends and recommendations.
            </p>
            <p className="text-text-muted mt-4">
              Reports are sent via email using the configured SMTP settings. 
              Make sure your mail configuration is set up correctly in <code>.env</code>.
            </p>
          </div>
        </div>
      </div>
    </AdminLayout>
  )
}
