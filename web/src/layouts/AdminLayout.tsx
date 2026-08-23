import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const adminNavigation = [
  { name: 'Dashboard', href: '/', icon: '📊' },
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

  // Determine navigation based on user role
  const isOwner = user?.role === 'owner'
  const isCustomer = user?.role === 'customer'
  const navigation = isCustomer ? customerNavigation : isOwner ? ownerNavigation : adminNavigation

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      super_admin: 'bg-red-500/20 text-red-500',
      admin: 'bg-accent/20 text-accent',
      owner: 'bg-success/20 text-success',
      customer: 'bg-blue-500/20 text-blue-500',
    }
    return styles[role] || 'bg-text-muted/20 text-text-muted'
  }

  return (
    <div className="min-h-screen flex">
      {/* Sidebar */}
      <aside className="w-64 bg-surface border-r border-border flex flex-col">
        {/* Logo */}
        <div className="h-16 flex items-center px-6 border-b border-border">
          <Link to="/" className="flex items-center gap-3">
            <span className="text-2xl">🎸</span>
            <span className="text-accent font-bold text-lg">StudioBook</span>
          </Link>
        </div>

        {/* Navigation */}
        <nav className="flex-1 py-4 px-3 space-y-1">
          {navigation.map((item) => {
            // Handle nested routes - exact match for root, prefix match for sub-routes
            const isActive = item.href === '/' 
              ? location.pathname === '/' 
              : location.pathname === item.href || location.pathname.startsWith(item.href + '/')
            return (
              <Link
                key={item.name}
                to={item.href}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-accent/10 text-accent'
                    : 'text-text-secondary hover:bg-surface-light hover:text-text-primary'
                }`}
              >
                <span className="text-lg">{item.icon}</span>
                <span className="font-medium">{item.name}</span>
              </Link>
            )
          })}
        </nav>

        {/* Quick Switch (for super_admin) */}
        {user?.role === 'super_admin' && (
          <div className="px-3 pb-2">
            <div className="p-3 bg-surface-light rounded-lg">
              <p className="text-text-muted text-xs mb-2">Switch Dashboard</p>
              <div className="flex gap-1 flex-wrap">
                <Link
                  to="/"
                  className={`flex-1 text-center py-1 text-xs rounded transition-colors ${
                    !isOwner && !isCustomer ? 'bg-accent text-primary' : 'bg-surface border border-border text-text-secondary hover:text-text-primary'
                  }`}
                >
                  Admin
                </Link>
                <Link
                  to="/owner/dashboard"
                  className={`flex-1 text-center py-1 text-xs rounded transition-colors ${
                    isOwner ? 'bg-accent text-primary' : 'bg-surface border border-border text-text-secondary hover:text-text-primary'
                  }`}
                >
                  Owner
                </Link>
                <Link
                  to="/customer/dashboard"
                  className={`flex-1 text-center py-1 text-xs rounded transition-colors ${
                    isCustomer ? 'bg-accent text-primary' : 'bg-surface border border-border text-text-secondary hover:text-text-primary'
                  }`}
                >
                  Customer
                </Link>
              </div>
            </div>
          </div>
        )}

        {/* User Profile */}
        <div className="p-4 border-t border-border">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-accent/20 rounded-full flex items-center justify-center">
              <span className="text-accent font-semibold">
                {user?.name?.charAt(0) || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-text-primary font-medium truncate">{user?.name}</p>
              <span className={`inline-block px-2 py-0.5 text-xs rounded ${getRoleBadge(user?.role || '')}`}>
                {user?.role?.replace('_', ' ')}
              </span>
            </div>
            <button
              onClick={handleLogout}
              className="text-text-muted hover:text-error transition-colors p-1"
              title="Logout"
            >
              🚪
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto">
        <div className="p-6">
          {children}
        </div>
      </main>
    </div>
  )
}
