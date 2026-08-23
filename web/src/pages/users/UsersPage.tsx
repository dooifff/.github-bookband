import { useState, useEffect } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface User {
  id: number
  name: string
  email: string
  role: string
  phone?: string
  email_verified_at?: string
  created_at: string
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)
  const [totalCount, setTotalCount] = useState(0)

  useEffect(() => {
    fetchUsers()
  }, [page, search, roleFilter])

  const fetchUsers = async () => {
    setLoading(true)
    setError('')
    try {
      const params = new URLSearchParams()
      if (search) params.append('search', search)
      if (roleFilter) params.append('role', roleFilter)
      params.append('page', page.toString())

      const response = await api.get(`/admin/users?${params.toString()}`)
      // Backend paginated response: { success, message, data: [...], meta: { current_page, last_page, per_page, total } }
      setUsers(response.data.data || [])
      setTotalPages(response.data.meta?.last_page || 1)
      setTotalCount(response.data.meta?.total || 0)
    } catch (err: any) {
      console.error('Failed to fetch users:', err)
      setError(err.response?.data?.message || 'Failed to load users')
      setUsers([])
    } finally {
      setLoading(false)
    }
  }

  const handleActivate = async (userId: number) => {
    try {
      await api.post(`/admin/users/${userId}/activate`)
      fetchUsers()
    } catch (err: any) {
      console.error('Failed to activate user:', err)
    }
  }

  const handleDeactivate = async (userId: number) => {
    try {
      await api.post(`/admin/users/${userId}/deactivate`)
      fetchUsers()
    } catch (err: any) {
      console.error('Failed to deactivate user:', err)
    }
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

  if (error && users.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div>
            <h1 className="text-2xl font-bold text-text-primary">Users</h1>
            <p className="text-text-secondary">Manage platform users</p>
          </div>
          <div className="bg-surface border border-border rounded-xl p-12 text-center">
            <p className="text-error mb-4">{error}</p>
            <button
              onClick={fetchUsers}
              className="px-4 py-2 bg-accent text-primary rounded-lg hover:bg-accent-hover transition-colors"
            >
              Retry
            </button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div>
          <h1 className="text-2xl font-bold text-text-primary">Users</h1>
          <p className="text-text-secondary">Manage platform users ({totalCount} total)</p>
        </div>

        {/* Filters */}
        <div className="bg-surface border border-border rounded-xl p-4">
          <div className="flex flex-wrap gap-4">
            <div className="flex-1 min-w-[200px]">
              <input
                type="text"
                value={search}
                onChange={(e) => { setSearch(e.target.value); setPage(1) }}
                placeholder="Search by name or email..."
                className="w-full bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary placeholder-text-muted focus:outline-none focus:border-accent"
              />
            </div>
            <select
              value={roleFilter}
              onChange={(e) => { setRoleFilter(e.target.value); setPage(1) }}
              className="bg-surface-light border border-border rounded-lg px-4 py-2 text-text-primary focus:outline-none focus:border-accent"
            >
              <option value="">All Roles</option>
              <option value="customer">Customer</option>
              <option value="owner">Owner</option>
              <option value="admin">Admin</option>
              <option value="super_admin">Super Admin</option>
            </select>
          </div>
        </div>

        {/* Users Table */}
        <div className="bg-surface border border-border rounded-xl overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-surface-light">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">User</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Role</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Phone</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Joined</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-text-muted uppercase tracking-wider">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {loading ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-text-muted">
                      <div className="animate-pulse">Loading users...</div>
                    </td>
                  </tr>
                ) : users.length === 0 ? (
                  <tr>
                    <td colSpan={5} className="px-6 py-12 text-center text-text-muted">
                      <p className="text-lg mb-2">No users found</p>
                      <p className="text-sm">Try adjusting your search</p>
                    </td>
                  </tr>
                ) : (
                  users.map((user) => (
                    <tr key={user.id} className="hover:bg-surface-light/50 transition-colors">
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-3">
                          <div className="w-10 h-10 bg-accent/20 rounded-full flex items-center justify-center">
                            <span className="text-accent font-semibold">{user.name?.charAt(0)}</span>
                          </div>
                          <div>
                            <p className="text-text-primary font-medium">{user.name}</p>
                            <p className="text-text-muted text-sm">{user.email}</p>
                          </div>
                        </div>
                      </td>
                      <td className="px-6 py-4">
                        <span className={`px-2 py-1 text-xs rounded ${getRoleBadge(user.role)}`}>
                          {user.role}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-text-secondary text-sm">{user.phone || '-'}</td>
                      <td className="px-6 py-4 text-text-secondary text-sm">
                        {new Date(user.created_at).toLocaleDateString('id-ID')}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          {user.role !== 'super_admin' && user.role !== 'admin' && (
                            <>
                              <button
                                onClick={() => handleActivate(user.id)}
                                className="px-2 py-1 text-xs bg-success/10 text-success rounded hover:bg-success/20 transition-colors"
                              >
                                Activate
                              </button>
                              <button
                                onClick={() => handleDeactivate(user.id)}
                                className="px-2 py-1 text-xs bg-error/10 text-error rounded hover:bg-error/20 transition-colors"
                              >
                                Deactivate
                              </button>
                            </>
                          )}
                          {user.email_verified_at ? (
                            <span className="text-success text-sm">✓ Verified</span>
                          ) : (
                            <span className="text-warning text-sm">Unverified</span>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-border flex items-center justify-between">
              <p className="text-text-muted text-sm">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <button
                  onClick={() => setPage(p => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50 transition-colors"
                >
                  Previous
                </button>
                <button
                  onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1 bg-surface-light border border-border rounded text-text-secondary hover:text-text-primary disabled:opacity-50 transition-colors"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  )
}
