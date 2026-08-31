import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface User {
  id: number
  name: string
  email: string
  role: string
  phone: string
  email_verified_at: string
  created_at: string
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  const fetchUsers = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      params.append('page', page.toString())
      if (roleFilter) params.append('role', roleFilter)
      const response = await api.get(`/admin/users?${params.toString()}`)
      setUsers(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch users:', error)
    } finally {
      setLoading(false)
    }
  }, [page, roleFilter])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      super_admin: 'bg-red-500/10 text-red-400 border border-red-500/20',
      admin: 'bg-accent/10 text-accent border border-accent/20',
      owner: 'bg-success/10 text-success border border-success/20',
      customer: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
    }
    return styles[role] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const filteredUsers = users.filter(u =>
    u.name.toLowerCase().includes(search.toLowerCase()) ||
    u.email.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <AdminLayout>
      <div className="space-y-6">
        <div className="animate-fade-in-up">
          <h1 className="text-3xl font-bold text-text-primary tracking-tight">Pengguna</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola pengguna platform</p>
        </div>

        {/* Filters */}
        <div className="flex gap-3 animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Cari pengguna..."
            className="input-luxury text-sm flex-1 max-w-xs"
          />
          <select value={roleFilter} onChange={(e) => { setRoleFilter(e.target.value); setPage(1) }} className="select-luxury text-sm">
            <option value="">Semua Peran</option>
            <option value="admin">Admin</option>
            <option value="owner">Pemilik</option>
            <option value="customer">Pelanggan</option>
          </select>
        </div>

        {/* Table */}
        <div className="card-luxury overflow-hidden animate-fade-in-up stagger-2">
          <div className="overflow-x-auto">
            <table className="w-full table-luxury">
              <thead>
                <tr>
                  <th>User</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Joined</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {loading ? (
                  <tr><td colSpan={5} className="px-6 py-16 text-center">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-sm">Memuat pengguna...</p>
                    </div>
                  </td></tr>
                ) : filteredUsers.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-16 text-center text-text-muted text-sm">Tidak ada pengguna ditemukan</td></tr>
                ) : (
                  filteredUsers.map((user) => (
                    <tr key={user.id}>
                      <td>
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/15 to-accent/5 flex items-center justify-center border border-accent/10">
                            <span className="text-accent text-xs font-semibold">{user.name?.charAt(0)}</span>
                          </div>
                          <p className="text-text-primary text-sm font-medium">{user.name}</p>
                        </div>
                      </td>
                      <td className="text-text-secondary text-sm">{user.email}</td>
                      <td><span className={`badge ${getRoleBadge(user.role)}`}>{user.role}</span></td>
                      <td className="text-text-muted text-sm">{new Date(user.created_at).toLocaleDateString('id-ID')}</td>
                      <td>
                        <span className={`badge ${user.email_verified_at ? 'bg-success/10 text-success border border-success/20' : 'bg-warning/10 text-warning border border-warning/20'}`}>
                          {user.email_verified_at ? 'Terverifikasi' : 'Belum Diverifikasi'}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {totalPages > 1 && (
            <div className="px-6 py-4 border-t border-border/40 flex items-center justify-between">
              <p className="text-text-muted text-xs">Page {page} of {totalPages}</p>
              <div className="flex gap-2">
                <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Sebelumnya</button>
                <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="btn-glass text-xs py-1.5 px-3 disabled:opacity-30">Selanjutnya</button>
              </div>
            </div>
          )}
        </div>
      </div>
    </AdminLayout>
  )
}
