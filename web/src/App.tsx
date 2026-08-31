import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './hooks/useAuth'
import LandingPage from './pages/landing/LandingPage'
import Login from './pages/auth/Login'
import Dashboard from './pages/dashboard/Dashboard'
import UsersPage from './pages/users/UsersPage'
import StudiosPage from './pages/studios/StudiosPage'
import BookingsPage from './pages/bookings/BookingsPage'
import SettingsPage from './pages/settings/SettingsPage'
import OwnerDashboard from './pages/owner/OwnerDashboard'
import OwnerStudiosPage from './pages/owner/OwnerStudiosPage'
import OwnerBookingsPage from './pages/owner/OwnerBookingsPage'
import OwnerRevenuePage from './pages/owner/OwnerRevenuePage'
import CustomerDashboard from './pages/customer/CustomerDashboard'
import CustomerBookingsPage from './pages/customer/CustomerBookingsPage'
import CustomerStudiosPage from './pages/customer/CustomerStudiosPage'
import CustomerFavoritesPage from './pages/customer/CustomerFavoritesPage'
import CustomerNotificationsPage from './pages/customer/CustomerNotificationsPage'
import StudioDetailPage from './pages/customer/StudioDetailPage'
import PaymentPage from './pages/customer/PaymentPage'
import PerformanceDashboard from './pages/dashboard/PerformanceDashboard'
import AlertsDashboard from './pages/dashboard/AlertsDashboard'
import ComparisonDashboard from './pages/dashboard/ComparisonDashboard'
import ScheduleSettings from './pages/settings/ScheduleSettings'
import './index.css'

function RoleRedirect() {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-primary">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
          <p className="text-text-muted text-sm">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  // Redirect based on role
  switch (user.role) {
    case 'admin':
    case 'super_admin':
      return <Navigate to="/admin" replace />
    case 'owner':
      return <Navigate to="/owner/dashboard" replace />
    case 'customer':
      return <Navigate to="/customer/dashboard" replace />
    default:
      return <Navigate to="/login" replace />
  }
}

function ProtectedRoute({ children, requiredRole }: { children: React.ReactNode; requiredRole?: string }) {
  const { user, loading } = useAuth()

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-primary">
        <div className="flex flex-col items-center gap-4">
          <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
          <p className="text-text-muted text-sm">Loading...</p>
        </div>
      </div>
    )
  }

  if (!user) {
    return <Navigate to="/login" replace />
  }

  // Role-based access control
  if (requiredRole) {
    const userRole = user.role
    const allowedRoles: Record<string, string[]> = {
      admin: ['admin', 'super_admin'],
      owner: ['owner', 'super_admin'],
      customer: ['customer'],
    }

    if (!allowedRoles[requiredRole]?.includes(userRole)) {
      // Redirect to correct dashboard for their role
      switch (userRole) {
        case 'owner': return <Navigate to="/owner/dashboard" replace />
        case 'customer': return <Navigate to="/customer/dashboard" replace />
        default: return <Navigate to="/admin" replace />
      }
    }
  }

  return <>{children}</>
}

function AppRoutes() {
  const { user } = useAuth()

  return (
    <Routes>
      {/* Public Routes */}
      <Route path="/" element={<LandingPage />} />
      <Route path="/login" element={user ? <RoleRedirect /> : <Login />} />

      {/* Admin Routes */}
      <Route path="/admin" element={
        <ProtectedRoute requiredRole="admin">
          <Dashboard />
        </ProtectedRoute>
      } />
      <Route path="/users" element={
        <ProtectedRoute requiredRole="admin">
          <UsersPage />
        </ProtectedRoute>
      } />
      <Route path="/studios" element={
        <ProtectedRoute requiredRole="admin">
          <StudiosPage />
        </ProtectedRoute>
      } />
      <Route path="/bookings" element={
        <ProtectedRoute requiredRole="admin">
          <BookingsPage />
        </ProtectedRoute>
      } />
      <Route path="/performance" element={
        <ProtectedRoute requiredRole="admin">
          <PerformanceDashboard />
        </ProtectedRoute>
      } />
      <Route path="/alerts" element={
        <ProtectedRoute requiredRole="admin">
          <AlertsDashboard />
        </ProtectedRoute>
      } />
      <Route path="/comparison" element={
        <ProtectedRoute requiredRole="admin">
          <ComparisonDashboard />
        </ProtectedRoute>
      } />
      <Route path="/settings" element={
        <ProtectedRoute>
          <SettingsPage />
        </ProtectedRoute>
      } />
      <Route path="/settings/schedule" element={
        <ProtectedRoute requiredRole="admin">
          <ScheduleSettings />
        </ProtectedRoute>
      } />

      {/* Owner Routes */}
      <Route path="/owner/dashboard" element={
        <ProtectedRoute requiredRole="owner">
          <OwnerDashboard />
        </ProtectedRoute>
      } />
      <Route path="/owner/studios" element={
        <ProtectedRoute requiredRole="owner">
          <OwnerStudiosPage />
        </ProtectedRoute>
      } />
      <Route path="/owner/bookings" element={
        <ProtectedRoute requiredRole="owner">
          <OwnerBookingsPage />
        </ProtectedRoute>
      } />
      <Route path="/owner/revenue" element={
        <ProtectedRoute requiredRole="owner">
          <OwnerRevenuePage />
        </ProtectedRoute>
      } />

      {/* Customer Routes */}
      <Route path="/customer/dashboard" element={
        <ProtectedRoute requiredRole="customer">
          <CustomerDashboard />
        </ProtectedRoute>
      } />
      <Route path="/customer/studios" element={
        <ProtectedRoute requiredRole="customer">
          <CustomerStudiosPage />
        </ProtectedRoute>
      } />
      <Route path="/customer/bookings" element={
        <ProtectedRoute requiredRole="customer">
          <CustomerBookingsPage />
        </ProtectedRoute>
      } />
      <Route path="/customer/studios/:slug" element={
        <ProtectedRoute requiredRole="customer">
          <StudioDetailPage />
        </ProtectedRoute>
      } />
      <Route path="/customer/payment/:bookingCode" element={
        <ProtectedRoute requiredRole="customer">
          <PaymentPage />
        </ProtectedRoute>
      } />
      <Route path="/customer/favorites" element={
        <ProtectedRoute requiredRole="customer">
          <CustomerFavoritesPage />
        </ProtectedRoute>
      } />
      <Route path="/customer/notifications" element={
        <ProtectedRoute requiredRole="customer">
          <CustomerNotificationsPage />
        </ProtectedRoute>
      } />

      {/* Catch all - show landing page */}
      <Route path="*" element={<LandingPage />} />
    </Routes>
  )
}

function App() {
  return (
    <Router>
      <AuthProvider>
        <div className="min-h-screen bg-primary">
          <AppRoutes />
        </div>
      </AuthProvider>
    </Router>
  )
}

export default App
