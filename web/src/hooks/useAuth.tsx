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
  /** Registrasi akun customer (backend selalu membuat role customer). */
  register: (name: string, email: string, password: string, phone?: string) => Promise<User>
  loginWithGoogle: (idToken: string, role?: 'customer' | 'owner') => Promise<User>
  requestPasswordReset: (email: string) => Promise<void>
  resetPassword: (token: string, email: string, password: string) => Promise<void>
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

  const register = useCallback(
    async (name: string, email: string, password: string, phone?: string) => {
      const response = await api.post('/auth/register', {
        name,
        email,
        password,
        ...(phone ? { phone } : {}),
      })
      const { user: userData, token: authToken } = response.data.data

      localStorage.setItem('token', authToken)
      localStorage.setItem('user', JSON.stringify(userData))
      setToken(authToken)
      setUser(userData)
      api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`

      return userData as User
    },
    []
  )

  /** Minta tautan reset password; backend membalas sukses walau email belum terdaftar. */
  const requestPasswordReset = useCallback(async (email: string) => {
    await api.post('/auth/forgot-password', { email })
  }, [])

  /** Selesaikan reset password dengan token dari email. */
  const resetPassword = useCallback(
    async (token: string, email: string, password: string) => {
      await api.post('/auth/reset-password', {
        token,
        email,
        password,
        password_confirmation: password,
      })
    },
    []
  )

  /**
   * Login/register lewat Google. ID token diverifikasi backend, yang akan
   * membuat akun otomatis bila email belum terdaftar.
   */
  const loginWithGoogle = useCallback(async (idToken: string, role?: 'customer' | 'owner') => {
    const response = await api.post('/auth/google', {
      id_token: idToken,
      ...(role ? { role } : {}),
    })
    const { user: userData, token: authToken } = response.data.data

    localStorage.setItem('token', authToken)
    localStorage.setItem('user', JSON.stringify(userData))
    setToken(authToken)
    setUser(userData)
    api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`

    return userData as User
  }, [])

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
        register,
        loginWithGoogle,
        requestPasswordReset,
        resetPassword,
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
