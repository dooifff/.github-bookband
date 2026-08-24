import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const adminNavigation = [
  { name: 'Dashboard', href: '/admin', icon: '📊' },
  { name: 'Users', href: '/users', icon: '👥' },
  { name: 'Studios', href: '/studios', icon: '🏠' },
  { name: 'Bookings', href: '/bookings', icon: '📅' },
  { name: 'Performance', href: '/performance', icon: '⚡' },
  { name: 'Alerts', href: '/alerts', icon: '🔔' },
  { name: 'Comparison', href: '/comparison', icon: '📈' },
  { name: 'Settings', href: '/settings', icon: '⚙️' },
]

const ownerNavigation = [
  { name: 'Dashboard', href: '/owner/dashboard', icon: '📊' },
  { name: 'My Studios', href: '/owner/studios', icon: '🏠' },
  { name: 'Bookings', href: '/owner/bookings', icon: '📅' },
  { name: 'Revenue', href: '/owner/revenue', icon: '💰' },
  { name: 'Settings', href: '/settings', icon: '⚙️' },
]

const customerNavigation = [
  { name: 'Dashboard', href: '/customer/dashboard', icon: '📊' },
  { name: 'Browse Studios', href: '/customer/studios', icon: '🔍' },
  { name: 'My Bookings', href: '/customer/bookings', icon: '📅' },
  { name: 'Favorites', href: '/customer/favorites', icon: '❤️' },
  { name: 'Notifications', href: '/customer/notifications', icon: '🔔' },
  { name: 'Settings', href: '/settings', icon: '⚙️' },
]

interface AdminLayoutProps {
  children: React.ReactNode
}

export default function AdminLayout({ children }: AdminLayoutProps) {
  const { user, logout } = useAuth()
  const location = useLocation()
  const navigate = useNavigate()

  const isOwner = user?.role === 'owner'
  const isCustomer = user?.role === 'customer'
  const navigation = isCustomer ? customerNavigation : isOwner ? ownerNavigation : adminNavigation

  const handleLogout = async () => {
    await logout()
    navigate('/')
  }

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      super_admin: 'bg-red-500/10 text-red-400 border border-red-500/20',
      admin:       'bg-accent/10 text-accent border border-accent/20',
      owner:       'bg-success/10 text-success border border-success/20',
      customer:    'bg-blue-500/10 text-blue-400 border border-blue-500/20',
    }
    return styles[role] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  return (
    <div className="min-h-screen flex bg-primary">
      {/* ─── Sidebar ─── */}
      <aside className="w-64 bg-surface border-r border-border flex flex-col fixed top-0 left-0 h-full z-30">
        {/* Logo area — links back to landing page */}
        <div className="h-16 flex items-center px-6 border-b border-border/60">
          <Link to="/" className="flex items-center gap-3 group">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/25 to-accent/5 flex items-center justify-center border border-accent/10 group-hover:border-accent/25 transition-all">
              <span className="text-sm">🎸</span>
            </div>
            <span className="gold-text-static font-bold text-base tracking-tight">StudioBook</span>
          </Link>
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-5 px-3 space-y-0.5 overflow-y-auto">
          {navigation.map((item) => {
            const isActive = location.pathname === item.href ||
              (item.href !== '/admin' && item.href !== '/settings' && location.pathname.startsWith(item.href + '/'))
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`relative flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 ${
                  isActive
                    ? 'bg-accent/8 text-accent sidebar-active'
                    : 'text-text-secondary hover:bg-surface-lighter/60 hover:text-text-primary'
                }`}
              >
                <span className="text-base w-5 text-center">{item.icon}</span>
                <span>{item.name}</span>
                {isActive && (
                  <div className="absolute right-3 w-1.5 h-1.5 rounded-full bg-accent/60" />
                )}
              </Link>
            )
          })}
        </nav>

        {/* Quick Switch (super_admin) */}
        {user?.role === 'super_admin' && (
          <div className="px-3 pb-3">
            <div className="glass-subtle rounded-xl p-3">
              <p className="text-text-muted text-[0.65rem] font-medium tracking-widest uppercase mb-2.5 px-1">Switch View</p>
              <div className="flex gap-1">
                <Link
                  to="/admin"
                  className={`flex-1 text-center py-1.5 text-[0.65rem] font-medium rounded-lg transition-all ${
                    !isOwner && !isCustomer
                      ? 'bg-accent text-primary shadow-sm shadow-accent/20'
                      : 'text-text-muted hover:text-text-secondary hover:bg-surface-lighter/60'
                  }`}
                >Admin</Link>
                <Link
                  to="/owner/dashboard"
                  className={`flex-1 text-center py-1.5 text-[0.65rem] font-medium rounded-lg transition-all ${
                    isOwner
                      ? 'bg-accent text-primary shadow-sm shadow-accent/20'
                      : 'text-text-muted hover:text-text-secondary hover:bg-surface-lighter/60'
                  }`}
                >Owner</Link>
                <Link
                  to="/customer/dashboard"
                  className={`flex-1 text-center py-1.5 text-[0.65rem] font-medium rounded-lg transition-all ${
                    isCustomer
                      ? 'bg-accent text-primary shadow-sm shadow-accent/20'
                      : 'text-text-muted hover:text-text-secondary hover:bg-surface-lighter/60'
                  }`}
                >Customer</Link>
              </div>
            </div>
          </div>
        )}

        {/* User profile */}
        <div className="p-3 border-t border-border/60">
          <div className="glass-subtle rounded-xl p-3 flex items-center gap-3">
            <div className="w-9 h-9 bg-gradient-to-br from-accent/20 to-accent/5 rounded-full flex items-center justify-center border border-accent/10 flex-shrink-0">
              <span className="text-accent text-sm font-semibold">
                {user?.name?.charAt(0) || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-text-primary text-sm font-medium truncate leading-tight">{user?.name}</p>
              <span className={`inline-block mt-0.5 px-2 py-0.5 text-[0.6rem] font-medium rounded-full ${getRoleBadge(user?.role || '')}`}>
                {user?.role?.replace('_', ' ')}
              </span>
            </div>
            <button
              onClick={handleLogout}
              className="text-text-muted hover:text-danger transition-colors p-1.5 rounded-lg hover:bg-danger/10"
              title="Logout"
            >
              <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
                <polyline points="16 17 21 12 16 7" />
                <line x1="21" y1="12" x2="9" y2="12" />
              </svg>
            </button>
          </div>
        </div>
      </aside>

      {/* ─── Main Content ─── */}
      <main className="flex-1 ml-64 min-h-screen">
        <div className="p-8 max-w-[1400px] mx-auto">
          {children}
        </div>
      </main>
    </div>
  )
}
