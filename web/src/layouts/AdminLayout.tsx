import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'

const adminNavigation = [
  { name: 'Dashboard', href: '/admin', icon: '📊' },
  { name: 'Users', href: '/users', icon: '👥' },
  { name: 'Studios', href: '/studios', icon: '🏠' },
  { name: 'Subscribers', href: '/subscribers', icon: '👥' },
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
  { name: 'Promos', href: '/owner/promos', icon: '🏷️' },
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

  const navigation = user?.role === 'customer' ? customerNavigation : user?.role === 'owner' ? ownerNavigation : adminNavigation

  const handleLogout = async () => {
    await logout()
    navigate('/')
  }

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      super_admin: 'bg-[#e53e3e]/10 text-[#e53e3e] border border-[#e53e3e]/20',
      admin:       'bg-[#e53e3e]/10 text-[#e53e3e] border border-[#e53e3e]/20',
      owner:       'bg-[#48bb78]/10 text-[#48bb78] border border-[#48bb78]/20',
      customer:    'bg-blue-500/10 text-blue-400 border border-blue-500/20',
    }
    return styles[role] || 'bg-white/5 text-gray-400 border border-white/10'
  }

  return (
    <div className="min-h-screen flex bg-[#050505]">
      {/* ─── Sidebar ─── */}
      <aside className="w-64 bg-[#080808] border-r border-white/5 flex flex-col fixed top-0 left-0 h-full z-30">
        {/* Logo area */}
        <div className="h-16 flex items-center px-6 border-b border-white/5">
          <Link to="/" className="flex items-center gap-3 group">
            <span className="font-black text-xl tracking-tight text-white" style={{ fontFamily: 'Impact, sans-serif', fontStyle: 'italic' }}>
              STUDIO<span className="text-[#e53e3e]">BOOK</span>
            </span>
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
                className={`relative flex items-center gap-3 px-3.5 py-2.5 rounded text-sm font-semibold transition-all duration-200 ${
                  isActive
                    ? 'bg-[#e53e3e]/10 text-[#e53e3e]'
                    : 'text-gray-400 hover:bg-[#111] hover:text-white'
                }`}
              >
                <span className="text-base w-5 text-center">{item.icon}</span>
                <span className="tracking-wide">{item.name}</span>
                {isActive && (
                  <div className="absolute left-0 top-1/2 -translate-y-1/2 w-[3px] h-[60%] bg-[#e53e3e] rounded-r" />
                )}
              </Link>
            )
          })}
        </nav>

        {/* User profile */}
        <div className="p-3 border-t border-white/5">
          <div className="flex items-center gap-3 p-2 rounded bg-[#0d0d0d] border border-white/5">
            <div className="w-9 h-9 bg-gradient-to-br from-[#e53e3e]/25 to-[#e53e3e]/5 rounded-full flex items-center justify-center border border-[#e53e3e]/15 flex-shrink-0">
              <span className="text-[#e53e3e] text-sm font-semibold">
                {user?.name?.charAt(0) || 'A'}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-white text-sm font-medium truncate leading-tight">{user?.name}</p>
              <span className={`inline-block mt-0.5 px-2 py-0.5 text-[0.6rem] font-semibold rounded ${getRoleBadge(user?.role || '')}`}>
                {user?.role?.replace('_', ' ')}
              </span>
            </div>
            <button
              onClick={handleLogout}
              className="text-gray-500 hover:text-[#e53e3e] transition-colors p-1.5 rounded hover:bg-[#e53e3e]/10"
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
      <main className="flex-1 ml-64 min-h-screen relative">
        <div className="relative z-10 px-8 py-6 max-w-[1400px] mx-auto">
          {children}
        </div>
      </main>
    </div>
  )
}
