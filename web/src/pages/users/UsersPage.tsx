import { useState, useEffect, useCallback } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'

interface User {
  id: number
  name: string
  email: string
  phone: string
  role: string
  is_active: boolean
  email_verified_at: string
  created_at: string
  studios_count: number
  bookings_count: number
}

interface UserDetail extends User {
  studios: { id: number; name: string; is_verified: boolean; is_active: boolean }[]
  bookings: { id: number; booking_code: string; studio: string; room: string; date: string; amount: number; status: string }[]
  stats: { total_bookings: number; total_spent: number }
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')
  const [roleFilter, setRoleFilter] = useState('')
  const [page, setPage] = useState(1)
  const [totalPages, setTotalPages] = useState(1)

  // Detail modal
  const [selectedUser, setSelectedUser] = useState<UserDetail | null>(null)
  const [detailLoading, setDetailLoading] = useState(false)

  // Edit role modal
  const [editingUser, setEditingUser] = useState<User | null>(null)
  const [newRole, setNewRole] = useState('')
  const [actionLoading, setActionLoading] = useState(false)

  // Create user modal
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [createForm, setCreateForm] = useState({ name: '', email: '', phone: '', password: '', role: 'owner' })
  const [createLoading, setCreateLoading] = useState(false)
  const [createError, setCreateError] = useState('')

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreateError('')
    setCreateLoading(true)
    try {
      await api.post('/admin/users', createForm)
      setShowCreateModal(false)
      setCreateForm({ name: '', email: '', phone: '', password: '', role: 'owner' })
      await fetchUsers()
    } catch (err: any) {
      const validationErrors = err.response?.data?.errors
      const specificMessage = validationErrors ? Object.values(validationErrors).flat().join('. ') : null
      setCreateError(specificMessage || err.response?.data?.message || 'Gagal membuat akun')
    } finally {
      setCreateLoading(false)
    }
  }

  const fetchUsers = useCallback(async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      params.append('page', page.toString())
      if (roleFilter) params.append('role', roleFilter)
      if (search) params.append('search', search)
      const response = await api.get(`/admin/users?${params.toString()}`)
      setUsers(response.data.data?.data || response.data.data || [])
      setTotalPages(response.data.data?.last_page || 1)
    } catch (error) {
      console.error('Failed to fetch users:', error)
    } finally {
      setLoading(false)
    }
  }, [page, roleFilter, search])

  useEffect(() => { fetchUsers() }, [fetchUsers])

  // Fetch user detail
  const fetchUserDetail = async (userId: number) => {
    setDetailLoading(true)
    try {
      const response = await api.get(`/admin/users/${userId}`)
      setSelectedUser(response.data.data)
    } catch (error) {
      console.error('Failed to fetch user detail:', error)
    } finally {
      setDetailLoading(false)
    }
  }

  // Toggle user active status
  const toggleUserStatus = async (user: User) => {
    if (!confirm(`${user.is_active ? 'Nonaktifkan' : 'Aktifkan'} user "${user.name}"?`)) return
    setActionLoading(true)
    try {
      const endpoint = user.is_active
        ? `/admin/users/${user.id}/deactivate`
        : `/admin/users/${user.id}/activate`
      await api.post(endpoint)
      await fetchUsers()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal mengubah status user')
    } finally {
      setActionLoading(false)
    }
  }

  // Update user role
  const updateUserRole = async () => {
    if (!editingUser || !newRole) return
    setActionLoading(true)
    try {
      await api.put(`/admin/users/${editingUser.id}`, { role: newRole })
      setEditingUser(null)
      await fetchUsers()
    } catch (error: any) {
      alert(error.response?.data?.message || 'Gagal mengubah role')
    } finally {
      setActionLoading(false)
    }
  }

  const getRoleBadge = (role: string) => {
    const styles: Record<string, string> = {
      super_admin: 'bg-red-500/10 text-red-400 border border-red-500/20',
      admin: 'bg-accent/10 text-accent border border-accent/20',
      owner: 'bg-success/10 text-success border border-success/20',
      customer: 'bg-blue-500/10 text-blue-400 border border-blue-500/20',
    }
    return styles[role] || 'bg-text-muted/10 text-text-muted border border-border'
  }

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="animate-fade-in-up">
          <h1 className="text-2xl font-bold text-text-primary tracking-tight">Pengguna</h1>
          <p className="text-text-secondary mt-1 text-sm">Kelola pengguna platform</p>
        </div>

        {/* Filters */}
        <div className="flex gap-3 items-center animate-fade-in-up stagger-1">
          <input
            type="text"
            value={search}
            onChange={(e) => { setSearch(e.target.value); setPage(1) }}
            placeholder="Cari pengguna..."
            className="input-luxury text-sm flex-1 max-w-xs"
          />
          <select value={roleFilter} onChange={(e) => { setRoleFilter(e.target.value); setPage(1) }} className="select-luxury text-sm">
            <option value="">Semua Peran</option>
            <option value="admin">Admin</option>
            <option value="owner">Pemilik</option>
            <option value="customer">Pelanggan</option>
          </select>
          <button
            onClick={() => setShowCreateModal(true)}
            className="btn-gold text-sm py-2 px-4 ml-auto"
          >
            + Buat Akun
          </button>
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
                  <th>Status</th>
                  <th>Aksi</th>
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
                ) : users.length === 0 ? (
                  <tr><td colSpan={5} className="px-6 py-16 text-center text-text-muted text-sm">Tidak ada pengguna ditemukan</td></tr>
                ) : (
                  users.map((user) => (
                    <tr key={user.id}>
                      <td>
                        <div className="flex items-center gap-3">
                          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/15 to-accent/5 flex items-center justify-center border border-accent/10">
                            <span className="text-accent text-xs font-semibold">{user.name?.charAt(0)}</span>
                          </div>
                          <div>
                            <button onClick={() => fetchUserDetail(user.id)} className="text-text-primary text-sm font-medium hover:text-accent transition-colors text-left">
                              {user.name}
                            </button>
                            <p className="text-text-muted text-xs">{user.phone || '-'}</p>
                          </div>
                        </div>
                      </td>
                      <td className="text-text-secondary text-sm">{user.email}</td>
                      <td>
                        <button
                          onClick={() => { setEditingUser(user); setNewRole(user.role) }}
                          className={`badge cursor-pointer hover:opacity-80 transition-opacity ${getRoleBadge(user.role)}`}
                        >
                          {user.role} ✎
                        </button>
                      </td>
                      <td>
                        <span className={`badge ${user.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                          {user.is_active ? 'Aktif' : 'Nonaktif'}
                        </span>
                      </td>
                      <td>
                        <div className="flex items-center gap-1.5">
                          <button
                            onClick={() => fetchUserDetail(user.id)}
                            className="px-2.5 py-1 text-[0.65rem] font-medium rounded-lg bg-surface-lighter/60 text-text-secondary hover:text-text-primary hover:bg-surface-light transition-all"
                          >
                            Detail
                          </button>
                          <button
                            onClick={() => toggleUserStatus(user)}
                            disabled={actionLoading || user.role === 'super_admin'}
                            className={`px-2.5 py-1 text-[0.65rem] font-medium rounded-lg transition-all disabled:opacity-40 ${
                              user.is_active
                                ? 'bg-danger/10 text-danger hover:bg-danger/20'
                                : 'bg-success/10 text-success hover:bg-success/20'
                            }`}
                          >
                            {user.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                          </button>
                        </div>
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

      {/* ─── User Detail Modal ─── */}
      {(selectedUser || detailLoading) && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setSelectedUser(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-2xl max-h-[85vh] overflow-y-auto glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Detail Pengguna</h2>
              <button onClick={() => setSelectedUser(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            {detailLoading ? (
              <div className="flex items-center justify-center py-12">
                <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
              </div>
            ) : selectedUser && (
              <>
                {/* Profile */}
                <div className="flex items-center gap-4 p-4 bg-surface-light/50 rounded-xl">
                  <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center border border-accent/10">
                    <span className="text-accent text-xl font-bold">{selectedUser.name?.charAt(0)}</span>
                  </div>
                  <div>
                    <h3 className="text-text-primary font-semibold">{selectedUser.name}</h3>
                    <p className="text-text-secondary text-sm">{selectedUser.email}</p>
                    <div className="flex gap-2 mt-1.5">
                      <span className={`badge text-[0.6rem] ${getRoleBadge(selectedUser.role)}`}>{selectedUser.role}</span>
                      <span className={`badge text-[0.6rem] ${selectedUser.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                        {selectedUser.is_active ? 'Aktif' : 'Nonaktif'}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-3">
                  <div className="bg-surface-light/50 rounded-xl p-3 text-center">
                    <p className="text-xl font-bold text-text-primary">{selectedUser.stats?.total_bookings || 0}</p>
                    <p className="text-text-muted text-xs mt-0.5">Booking</p>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3 text-center">
                    <p className="text-xl font-bold text-accent">{formatCurrency(selectedUser.stats?.total_spent || 0)}</p>
                    <p className="text-text-muted text-xs mt-0.5">Total Belanja</p>
                  </div>
                  <div className="bg-surface-light/50 rounded-xl p-3 text-center">
                    <p className="text-xl font-bold text-text-primary">{selectedUser.studios?.length || 0}</p>
                    <p className="text-text-muted text-xs mt-0.5">Studio</p>
                  </div>
                </div>

                {/* Studios owned */}
                {selectedUser.studios && selectedUser.studios.length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-text-primary mb-2">Studio Dimiliki</h4>
                    <div className="space-y-2">
                      {selectedUser.studios.map((studio) => (
                        <div key={studio.id} className="flex items-center justify-between p-3 bg-surface-light/50 rounded-xl">
                          <div className="flex items-center gap-2">
                            <span className="text-sm">🏠</span>
                            <span className="text-text-primary text-sm">{studio.name}</span>
                          </div>
                          <div className="flex gap-1.5">
                            {studio.is_verified && <span className="badge bg-accent/10 text-accent text-[0.6rem]">✓ Verified</span>}
                            <span className={`badge text-[0.6rem] ${studio.is_active ? 'bg-success/10 text-success' : 'bg-danger/10 text-danger'}`}>
                              {studio.is_active ? 'Aktif' : 'Nonaktif'}
                            </span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Recent Bookings */}
                {selectedUser.bookings && selectedUser.bookings.length > 0 && (
                  <div>
                    <h4 className="text-sm font-semibold text-text-primary mb-2">Booking Terbaru</h4>
                    <div className="space-y-1.5">
                      {selectedUser.bookings.map((booking) => (
                        <div key={booking.id} className="flex items-center justify-between p-3 bg-surface-light/50 rounded-xl">
                          <div>
                            <p className="text-text-primary text-sm font-medium">{booking.booking_code}</p>
                            <p className="text-text-muted text-xs">{booking.studio} • {booking.date}</p>
                          </div>
                          <div className="text-right">
                            <p className="text-text-primary text-sm">{formatCurrency(booking.amount)}</p>
                            <span className={`badge text-[0.6rem] ${
                              booking.status === 'completed' ? 'bg-success/10 text-success' :
                              booking.status === 'cancelled' ? 'bg-danger/10 text-danger' :
                              'bg-warning/10 text-warning'
                            }`}>{booking.status}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {/* ─── Create User Modal ─── */}
      {showCreateModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setShowCreateModal(false)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-sm glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Buat Akun Pengguna</h2>
              <button onClick={() => setShowCreateModal(false)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            {createError && (
              <div className="p-3 bg-danger/8 border border-danger/20 rounded-xl text-danger text-sm">
                {createError}
              </div>
            )}

            <form onSubmit={handleCreateUser} className="space-y-4">
              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Lengkap</label>
                <input
                  type="text"
                  value={createForm.name}
                  onChange={(e) => setCreateForm({...createForm, name: e.target.value})}
                  className="input-luxury w-full text-sm"
                  placeholder="Nama pengguna"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
                <input
                  type="email"
                  value={createForm.email}
                  onChange={(e) => setCreateForm({...createForm, email: e.target.value})}
                  className="input-luxury w-full text-sm"
                  placeholder="email@contoh.com"
                  required
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nomor Telepon</label>
                <input
                  type="tel"
                  value={createForm.phone}
                  onChange={(e) => setCreateForm({...createForm, phone: e.target.value})}
                  className="input-luxury w-full text-sm"
                  placeholder="08123456789"
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Password</label>
                <input
                  type="password"
                  value={createForm.password}
                  onChange={(e) => setCreateForm({...createForm, password: e.target.value})}
                  className="input-luxury w-full text-sm"
                  placeholder="Minimal 8 karakter"
                  required
                  minLength={8}
                />
              </div>

              <div className="space-y-1.5">
                <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Role</label>
                <select
                  value={createForm.role}
                  onChange={(e) => setCreateForm({...createForm, role: e.target.value})}
                  className="select-luxury w-full text-sm"
                >
                  <option value="owner">Owner (Pemilik Studio)</option>
                  <option value="customer">Customer (Pelanggan)</option>
                  <option value="admin">Admin</option>
                </select>
              </div>

              <div className="flex gap-2 justify-end pt-2">
                <button type="button" onClick={() => setShowCreateModal(false)} className="btn-glass text-sm py-2 px-4">Batal</button>
                <button
                  type="submit"
                  disabled={createLoading}
                  className="btn-gold text-sm py-2 px-4 disabled:opacity-40"
                >
                  {createLoading ? 'Membuat...' : 'Buat Akun'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ─── Edit Role Modal ─── */}
      {editingUser && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4" onClick={() => setEditingUser(null)}>
          <div className="absolute inset-0 bg-black/60 backdrop-blur-sm" />
          <div className="relative w-full max-w-sm glass-strong rounded-2xl p-6 space-y-5" onClick={(e) => e.stopPropagation()}>
            <div className="flex items-center justify-between">
              <h2 className="text-lg font-bold text-text-primary">Ubah Role</h2>
              <button onClick={() => setEditingUser(null)} className="text-text-muted hover:text-text-primary transition-colors p-1">✕</button>
            </div>

            <p className="text-text-secondary text-sm">
              Ubah role untuk <span className="text-text-primary font-medium">{editingUser.name}</span>
            </p>

            <select
              value={newRole}
              onChange={(e) => setNewRole(e.target.value)}
              className="select-luxury w-full text-sm"
              disabled={editingUser.role === 'super_admin'}
            >
              <option value="customer">Customer</option>
              <option value="owner">Owner</option>
              <option value="admin">Admin</option>
              {editingUser.role === 'super_admin' && <option value="super_admin">Super Admin</option>}
            </select>

            {editingUser.role === 'super_admin' && (
              <p className="text-warning text-xs">⚠ Super admin tidak bisa diubah role-nya</p>
            )}

            <div className="flex gap-2 justify-end">
              <button onClick={() => setEditingUser(null)} className="btn-glass text-sm py-2 px-4">Batal</button>
              <button
                onClick={updateUserRole}
                disabled={actionLoading || editingUser.role === 'super_admin' || newRole === editingUser.role}
                className="btn-gold text-sm py-2 px-4 disabled:opacity-40"
              >
                {actionLoading ? 'Menyimpan...' : 'Simpan'}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  )
}
