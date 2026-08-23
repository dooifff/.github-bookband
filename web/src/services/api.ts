import axios, { type AxiosResponse, type InternalAxiosRequestConfig } from 'axios'

// Base API URL - in dev mode, requests go through Vite proxy to avoid CORS
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1'

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 15000,
})

// ============================================
// Request Interceptor
// ============================================
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    // Attach token from localStorage
    const token = localStorage.getItem('token')
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`
    }

    // Log requests in development
    if (import.meta.env.DEV) {
      console.log(`[API] ${config.method?.toUpperCase()} ${config.url}`, config.data || '')
    }

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// ============================================
// Response Interceptor
// ============================================
interface ApiResponse<T = any> {
  success: boolean
  message: string
  data: T
  meta?: {
    current_page: number
    last_page: number
    per_page: number
    total: number
  }
  errors?: Record<string, string[]>
}

api.interceptors.response.use(
  (response: AxiosResponse<ApiResponse>) => {
    // Log responses in development
    if (import.meta.env.DEV) {
      console.log(`[API] ${response.config.method?.toUpperCase()} ${response.config.url}`, response.data)
    }

    // Transform response for easier use
    const apiData = response.data

    // If paginated response, flatten the data
    if (apiData.meta) {
      return {
        ...response,
        data: {
          ...apiData,
          items: apiData.data,
          pagination: apiData.meta,
        },
      }
    }

    return response
  },
  (error) => {
    const status = error.response?.status
    const message = error.response?.data?.message || 'An error occurred'

    // Handle specific error codes
    switch (status) {
      case 401:
        // Unauthorized - clear token and redirect to login
        localStorage.removeItem('token')
        localStorage.removeItem('user')
        if (window.location.pathname !== '/login') {
          window.location.href = '/login'
        }
        break

      case 403:
        // Forbidden
        console.error('[API] Forbidden:', message)
        break

      case 404:
        // Not found
        console.error('[API] Not Found:', error.config?.url)
        break

      case 422:
        // Validation errors
        console.error('[API] Validation Error:', error.response?.data?.errors)
        break

      case 429:
        // Rate limited
        console.error('[API] Rate Limited. Please slow down.')
        break

      case 500:
        // Server error
        console.error('[API] Server Error:', message)
        break

      default:
        if (error.code === 'ECONNABORTED') {
          console.error('[API] Request timeout')
        } else if (!error.response) {
          console.error('[API] Network error. Is the backend running?')
        }
    }

    return Promise.reject(error)
  }
)

// ============================================
// API Helper Methods
// ============================================

/**
 * Get paginated data from response
 */
export function getPaginationData(response: AxiosResponse<ApiResponse>) {
  return response.data.meta || {
    current_page: 1,
    last_page: 1,
    per_page: 15,
    total: 0,
  }
}

/**
 * Get items from paginated response
 */
export function getItems<T>(response: AxiosResponse<ApiResponse<T[]>>): T[] {
  return (response.data as any).items || response.data.data || []
}

/**
 * Extract validation errors from response
 */
export function getValidationErrors(error: any): Record<string, string[]> {
  return error.response?.data?.errors || {}
}

export default api
