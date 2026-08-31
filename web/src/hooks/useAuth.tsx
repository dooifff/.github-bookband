import { createContext, useContext, useState, useEffect, useCallback, useRef, type ReactNode } from 'react'
import api from '../services/api'

interface User {
  id: number
  name: string
  email: string
  role: string
  phone?: string
  avatar?: string
  email_verified_at?: string
}

interface AuthContextType {
  user: User | null
  token: string | null
  loading: boolean
  login: (email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  updateUser: (data: Partial<User>) => void
  isAdmin: boolean
  isOwner: boolean
  isCustomer: boolean
}

const AuthContext = createContext<AuthContextType | undefined>(undefined)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [token, setToken] = useState<string | null>(localStorage.getItem('token'))
  const loadingRef = useRef(true)
  const [loading, setLoading] = useState(true)

  const fetchUser = useCallback(async () => {
    try {
      const response = await api.get('/auth/me')
      const userData = response.data.data
      setUser(userData)
      localStorage.setItem('user', JSON.stringify(userData))
    } catch (error) {
      console.error('Failed to fetch user:', error)
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      setToken(null)
      setUser(null)
      delete api.defaults.headers.common['Authorization']
    } finally {
      setLoading(false)
      loadingRef.current = false
    }
  }, [])

  useEffect(() => {
    if (token) {
      api.defaults.headers.common['Authorization'] = `Bearer ${token}`
      fetchUser()
    } else {
      setLoading(false)
      loadingRef.current = false
    }
  }, [token, fetchUser])

  const login = async (email: string, password: string) => {
    const response = await api.post('/auth/login', { email, password })
    const { user: userData, token: authToken } = response.data.data

    localStorage.setItem('token', authToken)
    localStorage.setItem('user', JSON.stringify(userData))
    setToken(authToken)
    setUser(userData)
    api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`
  }

  const logout = useCallback(async () => {
    try {
      if (token) {
        await api.post('/auth/logout')
      }
    } catch (error) {
      console.error('Logout error:', error)
    } finally {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      setToken(null)
      setUser(null)
      delete api.defaults.headers.common['Authorization']
    }
  }, [token])

  const updateUser = (data: Partial<User>) => {
    setUser((prev) => {
      if (!prev) return null
      const updated = { ...prev, ...data }
      localStorage.setItem('user', JSON.stringify(updated))
      return updated
    })
  }

  // Role helpers
  const isAdmin = user?.role === 'admin' || user?.role === 'super_admin'
  const isOwner = user?.role === 'owner' || user?.role === 'super_admin'
  const isCustomer = user?.role === 'customer'

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        loading,
        login,
        logout,
        updateUser,
        isAdmin,
        isOwner,
        isCustomer,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
