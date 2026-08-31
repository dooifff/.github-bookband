import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface Notification {
  id: number
  type: string
  title: string
  body: string
  is_read: boolean
  data: any
  created_at: string
}

export default function CustomerNotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(true)
  const [unreadCount, setUnreadCount] = useState(0)

  const fetchNotifications = useCallback(async () => {
    try {
      const [notifRes, countRes] = await Promise.all([
        api.get('/notifications'),
        api.get('/notifications/unread-count'),
      ])
      setNotifications(notifRes.data.data || [])
      setUnreadCount(countRes.data.data?.unread_count || 0)
    } catch (error) {
      console.error('Failed to fetch notifications:', error)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchNotifications() }, [fetchNotifications])

  const markAsRead = async (id: number) => {
    try {
      await api.post(`/notifications/${id}/read`)
      setNotifications(notifications.map(n => n.id === id ? { ...n, is_read: true } : n))
      setUnreadCount(prev => Math.max(0, prev - 1))
    } catch (error) {
      console.error('Failed to mark as read:', error)
    }
  }

  const markAllAsRead = async () => {
    try {
      await api.post('/notifications/read-all')
      setNotifications(notifications.map(n => ({ ...n, is_read: true })))
      setUnreadCount(0)
    } catch (error) {
      console.error('Failed to mark all as read:', error)
    }
  }

  const getIcon = (type: string) => {
    switch (type) {
      case 'booking': return '📅'
      case 'payment': return '💳'
      case 'promo': return '🎁'
      default: return '🔔'
    }
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="flex items-center justify-between animate-fade-in-up">
          <div>
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Notifications</h1>
            <p className="text-text-secondary mt-1 text-sm">
              {unreadCount > 0 ? `${unreadCount} notifikasi belum dibaca` : 'Semua sudah dibaca!'}
            </p>
          </div>
          {unreadCount > 0 && (
            <button onClick={markAllAsRead} className="btn-gold text-sm">
              Tandai semua sudah dibaca
            </button>
          )}
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              <p className="text-text-muted text-sm">Memuat notifikasi...</p>
            </div>
          </div>
        ) : notifications.length === 0 ? (
          <div className="card-luxury p-16 text-center animate-fade-in">
            <span className="text-4xl mb-4 block">🔔</span>
            <p className="text-text-muted text-lg">Tidak ada notifikasi</p>
          </div>
        ) : (
          <div className="space-y-2">
            {notifications.map((notif, i) => (
              <div
                key={notif.id}
                className={`card-luxury p-5 flex items-start gap-4 cursor-pointer animate-fade-in-up stagger-${Math.min(i + 1, 8)} ${
                  !notif.is_read ? 'border-accent/15 bg-accent/[0.02]' : ''
                }`}
                onClick={() => !notif.is_read && markAsRead(notif.id)}
              >
                <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-lg flex-shrink-0 ${
                  !notif.is_read ? 'bg-accent/10 border border-accent/10' : 'bg-surface-lighter'
                }`}>
                  {getIcon(notif.type)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-text-primary text-sm font-medium">{notif.title}</p>
                    {!notif.is_read && <span className="w-2 h-2 bg-accent rounded-full flex-shrink-0" />}
                  </div>
                  <p className="text-text-secondary text-sm mt-0.5">{notif.body}</p>
                  <p className="text-text-muted text-xs mt-1.5">
                    {new Date(notif.created_at).toLocaleString('id-ID')}
                  </p>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
