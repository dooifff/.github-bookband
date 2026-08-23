import { useState, useEffect } from 'react'
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

  useEffect(() => {
    fetchNotifications()
  }, [])

  const fetchNotifications = async () => {
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
  }

  const markAsRead = async (id: number) => {
    try {
      await api.post(`/notifications/${id}/read`)
      setNotifications(notifications.map(n =>
        n.id === id ? { ...n, is_read: true } : n
      ))
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
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Notifications</h1>
            <p className="text-text-secondary">
              {unreadCount > 0 ? `${unreadCount} unread notifications` : 'All caught up!'}
            </p>
          </div>
          {unreadCount > 0 && (
            <button
              onClick={markAllAsRead}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors text-sm"
            >
              Mark all as read
            </button>
          )}
        </div>

        {loading ? (
          <div className="flex items-center justify-center h-32">
            <div className="text-accent animate-pulse">Loading notifications...</div>
          </div>
        ) : notifications.length === 0 ? (
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <span className="text-4xl mb-4 block">🔔</span>
            <p className="text-text-muted text-lg">No notifications</p>
          </div>
        ) : (
          <div className="space-y-2">
            {notifications.map((notif) => (
              <div
                key={notif.id}
                className={`bg-surface border rounded-xl p-4 flex items-start gap-4 transition-colors ${
                  notif.is_read ? 'border-border' : 'border-accent/30 bg-accent/5'
                }`}
                onClick={() => !notif.is_read && markAsRead(notif.id)}
              >
                <div className="w-10 h-10 bg-accent/10 rounded-full flex items-center justify-center text-lg flex-shrink-0">
                  {getIcon(notif.type)}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-text-primary font-medium">{notif.title}</p>
                    {!notif.is_read && (
                      <span className="w-2 h-2 bg-accent rounded-full"></span>
                    )}
                  </div>
                  <p className="text-text-secondary text-sm mt-0.5">{notif.body}</p>
                  <p className="text-text-muted text-xs mt-1">
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
