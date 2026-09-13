import { useState, useEffect, useCallback, useRef } from 'react'
import AdminLayout from '../../layouts/AdminLayout'
import api from '../../services/api'
import { searchProvinces, searchCities } from '../../data/indonesianRegions'

interface Studio {
  id: number
  name: string
  slug: string
  city: string
  province: string
  is_active: boolean
  is_verified: boolean
  average_rating: number
  total_reviews: number
  rooms_count: number
  images?: { id: number; url: string; caption?: string | null; is_primary?: boolean }[]
  subscription?: {
    status: 'none' | 'active' | 'expired' | 'removed'
    expires_at: string | null
    warning_level: number
    last_warning_at: string | null
  }
  created_at: string
}

interface Room {
  id: number
  studio_id: number
  name: string
  description: string | null
  capacity: number
  price_per_hour: number
  formatted_price: string
  is_active: boolean
}

interface Facility {
  id: number
  studio_id: number
  name: string
  description: string | null
  icon: string | null
  image: string | null
  is_active: boolean
}

export default function OwnerStudiosPage() {
  const [studios, setStudios] = useState<Studio[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [showCreateModal, setShowCreateModal] = useState(false)
  const [creating, setCreating] = useState(false)
  const [formData, setFormData] = useState({ name: '', address: '', city: '', province: '', phone: '', email: '' })

  // Province dropdown state
  const [provinceQuery, setProvinceQuery] = useState('')
  const [showProvinceDropdown, setShowProvinceDropdown] = useState(false)
  const provinceRef = useRef<HTMLDivElement>(null)

  // City dropdown state
  const [cityQuery, setCityQuery] = useState('')
  const [showCityDropdown, setShowCityDropdown] = useState(false)
  const cityRef = useRef<HTMLDivElement>(null)

  // Edit studio state
  const [editStudio, setEditStudio] = useState<Studio | null>(null)
  const [editForm, setEditForm] = useState({ name: '', address: '', city: '', province: '', phone: '', email: '' })
  const [editProvinceQuery, setEditProvinceQuery] = useState('')
  const [showEditProvinceDropdown, setShowEditProvinceDropdown] = useState(false)
  const [editCityQuery, setEditCityQuery] = useState('')
  const [showEditCityDropdown, setShowEditCityDropdown] = useState(false)
  const editProvinceRef = useRef<HTMLDivElement>(null)
  const editCityRef = useRef<HTMLDivElement>(null)

  // Room management state
  const [selectedStudio, setSelectedStudio] = useState<Studio | null>(null)
  const [rooms, setRooms] = useState<Room[]>([])
  const [roomsLoading, setRoomsLoading] = useState(false)
  const [showRoomModal, setShowRoomModal] = useState(false)
  const [editingRoom, setEditingRoom] = useState<Room | null>(null)
  const [roomForm, setRoomForm] = useState({ name: '', description: '', capacity: '1', price_per_hour: '' })
  const [roomSaving, setRoomSaving] = useState(false)

  // Facility management state
  const [showFacilityModal, setShowFacilityModal] = useState(false)
  const [facilityStudio, setFacilityStudio] = useState<Studio | null>(null)
  const [facilities, setFacilities] = useState<Facility[]>([])
  const [facilitiesLoading, setFacilitiesLoading] = useState(false)
  const [facilityFormOpen, setFacilityFormOpen] = useState(false)
  const [editingFacility, setEditingFacility] = useState<Facility | null>(null)
  const [facilityForm, setFacilityForm] = useState({ name: '', description: '', icon: '', is_active: true })
  const [facilityImageFile, setFacilityImageFile] = useState<File | null>(null)
  const [facilityImagePreview, setFacilityImagePreview] = useState<string | null>(null)
  const [facilitySaving, setFacilitySaving] = useState(false)

  // Studio image upload state
  const [showImageUploadModal, setShowImageUploadModal] = useState(false)
  const [imageStudio, setImageStudio] = useState<Studio | null>(null)
  const [studioImages, setStudioImages] = useState<{ id: number; url: string; caption?: string | null; is_primary?: boolean }[]>([])
  const [uploading, setUploading] = useState(false)
  const [studioImageFile, setStudioImageFile] = useState<File | null>(null)
  const [studioImagePreview, setStudioImagePreview] = useState<string | null>(null)
  const [studioImageCaption, setStudioImageCaption] = useState('')
  const [setPrimary, setSetPrimary] = useState(false)

  const filteredEditProvinces = searchProvinces(editProvinceQuery)
  const filteredEditCities = editForm.province ? searchCities(editForm.province, editCityQuery) : []

  const filteredProvinces = searchProvinces(provinceQuery)
  const filteredCities = formData.province ? searchCities(formData.province, cityQuery) : []

  // Close dropdowns on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (provinceRef.current && !provinceRef.current.contains(e.target as Node)) {
        setShowProvinceDropdown(false)
      }
      if (cityRef.current && !cityRef.current.contains(e.target as Node)) {
        setShowCityDropdown(false)
      }
      if (editProvinceRef.current && !editProvinceRef.current.contains(e.target as Node)) {
        setShowEditProvinceDropdown(false)
      }
      if (editCityRef.current && !editCityRef.current.contains(e.target as Node)) {
        setShowEditCityDropdown(false)
      }
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [])

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(amount)

  const fetchStudios = useCallback(async () => {
    setLoading(true)
    setError('')
    try {
      const response = await api.get('/owner/studios')
      const data = response.data.data
      setStudios(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch studios:', err)
      setError(err.response?.data?.message || 'Gagal memuat studio')
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => { fetchStudios() }, [fetchStudios])

  const handleCreateStudio = async (e: React.FormEvent) => {
    e.preventDefault()
    setCreating(true)
    try {
      await api.post('/owner/studios', formData)
      setShowCreateModal(false)
      setFormData({ name: '', address: '', city: '', province: '', phone: '', email: '' })
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal membuat studio')
    } finally {
      setCreating(false)
    }
  }

  const handleDeleteStudio = async (studioId: number) => {
    if (!confirm('Apakah Anda yakin ingin menghapus studio ini?')) return
    try { await api.delete(`/owner/studios/${studioId}`); fetchStudios() } catch (err: any) { alert(err.response?.data?.message || 'Gagal menghapus studio') }
  }

  const handleRenewSubscription = async (studio: Studio) => {
    if (!confirm(`Perpanjang langganan studio "${studio.name}" selama 1 bulan?`)) return
    try {
      await api.post(`/owner/studios/${studio.id}/subscription/renew`)
      alert('✅ Langganan berhasil diperpanjang. Studio Anda kembali aktif!')
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal memperpanjang langganan')
    }
  }

  const subscriptionBadge = (studio: Studio): { text: string; className: string } => {
    const sub = studio.subscription
    if (!sub || sub.status === 'none') return { text: 'Belum berlangganan', className: 'text-text-muted/70' }
    if (sub.status === 'removed') return { text: 'Studio dihapus (langganan berakhir)', className: 'text-danger' }
    if (sub.status === 'expired') {
      const level = sub.warning_level || 0
      if (level >= 2) return { text: '⚠️ Peringatan terakhir — segera perpanjang atau studio akan dihapus', className: 'text-danger' }
      if (level >= 1) return { text: '⚠️ Peringatan 1 terkirim — segera perpanjang', className: 'text-warning' }
      return { text: '⚠️ Masa aktif telah berakhir — segera perpanjang', className: 'text-warning' }
    }
    const exp = sub.expires_at ? new Date(sub.expires_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '–'
    return { text: `✅ Langganan aktif s.d. ${exp}`, className: 'text-success' }
  }

  // ─── Edit Studio ───
  const openEditStudio = (studio: Studio) => {
    setEditStudio(studio)
    setEditForm({ name: studio.name, address: '', city: studio.city, province: studio.province, phone: '', email: '' })
    setEditProvinceQuery('')
    setEditCityQuery('')
  }

  const handleUpdateStudio = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!editStudio) return
    try {
      await api.put(`/owner/studios/${editStudio.id}`, editForm)
      setEditStudio(null)
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal memperbarui studio')
    }
  }

  // ─── Room Management ───
  const openRoomModal = async (studio: Studio) => {
    setSelectedStudio(studio)
    setShowRoomModal(true)
    setRoomsLoading(true)
    try {
      const res = await api.get(`/owner/studios/${studio.id}/rooms`)
      const data = res.data.data
      setRooms(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch rooms:', err)
      setRooms([])
    } finally {
      setRoomsLoading(false)
    }
  }

  const openAddRoom = () => {
    setEditingRoom(null)
    setRoomForm({ name: '', description: '', capacity: '1', price_per_hour: '' })
    setShowRoomModal(true)
  }

  const openEditRoom = (room: Room) => {
    setEditingRoom(room)
    setRoomForm({
      name: room.name,
      description: room.description || '',
      capacity: room.capacity.toString(),
      price_per_hour: room.price_per_hour.toString(),
    })
  }

  const handleSaveRoom = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!selectedStudio) return
    setRoomSaving(true)
    try {
      const payload = {
        name: roomForm.name,
        description: roomForm.description || null,
        capacity: parseInt(roomForm.capacity),
        price_per_hour: parseFloat(roomForm.price_per_hour),
      }
      if (editingRoom) {
        await api.put(`/owner/studios/${selectedStudio.id}/rooms/${editingRoom.id}`, payload)
      } else {
        await api.post(`/owner/studios/${selectedStudio.id}/rooms`, payload)
      }
      // Refresh rooms
      const res = await api.get(`/owner/studios/${selectedStudio.id}/rooms`)
      const data = res.data.data
      setRooms(Array.isArray(data) ? data : data?.data || [])
      setEditingRoom(null)
      setRoomForm({ name: '', description: '', capacity: '1', price_per_hour: '' })
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menyimpan ruangan')
    } finally {
      setRoomSaving(false)
    }
  }

  const handleDeleteRoom = async (roomId: number) => {
    if (!selectedStudio) return
    if (!confirm('Hapus ruangan ini?')) return
    try {
      await api.delete(`/owner/studios/${selectedStudio.id}/rooms/${roomId}`)
      setRooms((prev) => prev.filter((r) => r.id !== roomId))
      fetchStudios()
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menghapus ruangan')
    }
  }

  // ─── Facility Management ───
  const openFacilityModal = async (studio: Studio) => {
    setFacilityStudio(studio)
    setShowFacilityModal(true)
    setFacilitiesLoading(true)
    setFacilityFormOpen(false)
    setEditingFacility(null)
    try {
      const res = await api.get(`/owner/studios/${studio.id}/facilities`)
      const data = res.data.data
      setFacilities(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      console.error('Failed to fetch facilities:', err)
      setFacilities([])
    } finally {
      setFacilitiesLoading(false)
    }
  }

  const openAddFacility = () => {
    setEditingFacility(null)
    setFacilityForm({ name: '', description: '', icon: '', is_active: true })
    setFacilityImageFile(null)
    setFacilityImagePreview(null)
    setFacilityFormOpen(true)
  }

  const openEditFacility = (facility: Facility) => {
    setEditingFacility(facility)
    setFacilityForm({
      name: facility.name,
      description: facility.description || '',
      icon: facility.icon || '',
      is_active: facility.is_active,
    })
    setFacilityImageFile(null)
    setFacilityImagePreview(facility.image)
    setFacilityFormOpen(true)
  }

  const handleFacilityImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setFacilityImageFile(file)
    setFacilityImagePreview(URL.createObjectURL(file))
  }

  const handleSaveFacility = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!facilityStudio) return
    setFacilitySaving(true)
    try {
      const fd = new FormData()
      fd.append('name', facilityForm.name)
      if (facilityForm.description) fd.append('description', facilityForm.description)
      if (facilityForm.icon) fd.append('icon', facilityForm.icon)
      fd.append('is_active', facilityForm.is_active ? '1' : '0')
      if (facilityImageFile) {
        fd.append('image', facilityImageFile)
        console.log('[Facility] Upload file:', facilityImageFile.name, facilityImageFile.type, facilityImageFile.size, 'bytes')
      }

      if (editingFacility) {
        await api.put(`/owner/studios/${facilityStudio.id}/facilities/${editingFacility.id}`, fd)
      } else {
        await api.post(`/owner/studios/${facilityStudio.id}/facilities`, fd)
      }

      // Refresh facilities list
      const res = await api.get(`/owner/studios/${facilityStudio.id}/facilities`)
      const data = res.data.data
      setFacilities(Array.isArray(data) ? data : data?.data || [])
      setFacilityFormOpen(false)
      setEditingFacility(null)
    } catch (err: any) {
      // Tampilkan detail validasi Laravel kalau ada
      const msg = err.response?.data?.message || 'Gagal menyimpan fasilitas'
      const errors = err.response?.data?.errors
      if (errors) {
        const detail = Object.entries(errors)
          .map(([field, msgs]) => `${field}: ${Array.isArray(msgs) ? msgs.join(', ') : msgs}`)
          .join('\n')
        alert(`${msg}\n\n${detail}`)
      } else {
        alert(msg)
      }
      console.error('[Facility] Save error:', err.response || err)
    } finally {
      setFacilitySaving(false)
    }
  }

  const handleDeleteFacility = async (facilityId: number) => {
    if (!facilityStudio) return
    if (!confirm('Hapus fasilitas ini?')) return
    try {
      await api.delete(`/owner/studios/${facilityStudio.id}/facilities/${facilityId}`)
      setFacilities((prev) => prev.filter((f) => f.id !== facilityId))
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menghapus fasilitas')
    }
  }

  // ─── Studio Image Upload ───
  const openImageUpload = (studio: Studio) => {
    setImageStudio(studio)
    setStudioImages(Array.isArray(studio.images) ? studio.images : [])
    setStudioImageFile(null)
    setStudioImagePreview(null)
    setStudioImageCaption('')
    setSetPrimary(false)
    setShowImageUploadModal(true)
  }

  const handleStudioImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    setStudioImageFile(file)
    setStudioImagePreview(URL.createObjectURL(file))
  }

  const handleSaveStudioImage = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!imageStudio) return
    setUploading(true)
    try {
      const fd = new FormData()
      if (studioImageFile) fd.append('image', studioImageFile)
      if (studioImageCaption) fd.append('caption', studioImageCaption)
      fd.append('is_primary', setPrimary ? '1' : '0')

      const res = await api.post(`/owner/studios/${imageStudio.id}/images`, fd)
      const newImage = res.data.data

      setStudioImages((prev) => [...prev, newImage])
      setShowImageUploadModal(false)
      setStudioImageFile(null)
      setStudioImagePreview(null)
      setStudioImageCaption('')
      setSetPrimary(false)

      // Refresh studio list biar images termuat
      const refreshRes = await api.get('/owner/studios')
      const data = refreshRes.data.data
      setStudios(Array.isArray(data) ? data : data?.data || [])
    } catch (err: any) {
      const msg = err.response?.data?.message || 'Gagal upload gambar'
      const errors = err.response?.data?.errors
      if (errors) {
        const detail = Object.entries(errors)
          .map(([field, msgs]) => `${field}: ${Array.isArray(msgs) ? msgs.join(', ') : msgs}`)
          .join('\n')
        alert(`${msg}\n\n${detail}`)
      } else {
        alert(msg)
      }
      console.error('[StudioImage] Upload error:', err.response || err)
    } finally {
      setUploading(false)
    }
  }

  const handleDeleteStudioImage = async (imageId: number) => {
    if (!imageStudio) return
    if (!confirm('Hapus gambar ini?')) return
    try {
      await api.delete(`/owner/studios/${imageStudio.id}/images/${imageId}`)
      setStudioImages((prev) => prev.filter((im) => im.id !== imageId))
    } catch (err: any) {
      alert(err.response?.data?.message || 'Gagal menghapus gambar')
    }
  }

  const handleSetPrimary = async (imageId: number) => {
    if (!imageStudio) return
    try {
      // endpoint khusus nggak ada, jadi kita set manual lewat update studio images table
      // Cek dulu apakah backend ada method setPrimary; kalau belum, skip.
      await api.put(`/owner/studios/${imageStudio.id}/images/${imageId}/set-primary`, {})
      setStudioImages((prev) => prev.map((im) => ({ ...im, is_primary: im.id === imageId })))
    } catch (err: any) {
      // Jika endpoint belum ada, abaikan (opsional)
      console.warn('Set primary tidak didukung:', err.message)
    }
  }

  if (error && studios.length === 0) {
    return (
      <AdminLayout>
        <div className="space-y-6">
          <div className="animate-fade-in-up">
            <h1 className="text-3xl font-bold text-text-primary tracking-tight">Studio Saya</h1>
            <p className="text-text-secondary mt-1 text-sm">Kelola studio Anda</p>
          </div>
          <div className="card-luxury p-12 text-center">
            <p className="text-danger mb-4">{error}</p>
            <button onClick={fetchStudios} className="btn-gold text-sm">Coba Lagi</button>
          </div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between animate-fade-in-up">
          <div className="flex items-center gap-4">
            {/* Decorative music note icon */}
            <div className="hidden sm:flex items-center gap-1.5 text-text-muted">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-accent/15 to-accent/5 flex items-center justify-center border border-accent/10 shadow-inner">
                <svg className="w-5 h-5 text-accent/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <path d="M9 18V5l12-2v13" strokeLinecap="round" strokeLinejoin="round" />
                  <circle cx="6" cy="18" r="3" />
                  <circle cx="18" cy="16" r="3" />
                </svg>
              </div>
              <span className="text-text-muted/50 text-xs uppercase tracking-widest">Dashboard</span>
            </div>
            <div>
              <h1 className="text-3xl font-bold text-text-primary tracking-tight flex items-center gap-3">
                <span className="relative">
                  Studio Saya
                  <span className="absolute -bottom-1 left-0 right-0 h-0.5 bg-gradient-to-r from-accent/30 via-accent/50 to-accent/30 rounded-full" />
                </span>
              </h1>
              <p className="text-text-muted mt-0.5 text-sm flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-accent/40 animate-pulse" />
                Kelola studio dan musik Anda
              </p>
            </div>
          </div>
          <button onClick={() => setShowCreateModal(true)} className="btn-gold text-sm flex items-center gap-2 shadow-lg concert-shadow-md">
            <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14" strokeLinecap="round" /></svg>
            Tambah Studio
          </button>
        </div>

        {/* Studios - Band Theme Grid */}
        {loading ? (
          <div className="flex items-center justify-center h-64">
            <div className="flex flex-col items-center gap-4 animate-fade-in">
              {/* Loading spinner with spotlight effect */}
              <div className="relative">
                <div className="absolute -inset-4 rounded-full bg-accent/5 blur-2xl animate-pulse" />
                <div className="relative">
                  <div className="absolute -inset-2 rounded-full border border-accent/10 animate-pulse" />
                  <div className="w-16 h-16 border-2 border-accent/40 border-t-accent rounded-full animate-spin" />
                  <div className="absolute inset-0 rounded-full bg-accent/5 animate-ping" />
                </div>
                {/* Sound wave decoration */}
                <div className="absolute -bottom-3 left-1/2 -translate-x-1/2 flex items-end gap-1">
                  <div className="w-1 bg-accent/30 rounded-full animate-sound-wave" style={{ animationDelay: '0s' }} />
                  <div className="w-1.5 bg-accent/40 rounded-full animate-sound-wave" style={{ animationDelay: '0.15s' }} />
                  <div className="w-1 bg-accent/30 rounded-full animate-sound-wave" style={{ animationDelay: '0.3s' }} />
                </div>
              </div>
              <p className="text-text-muted text-sm animate-pulse">Memuat studio...</p>
            </div>
          </div>
        ) : studios.length === 0 ? (
          <div className="animate-fade-in">
            <div className="stage-glow rounded-2xl p-16">
              <div className="relative overflow-hidden rounded-2xl">
                {/* Stage spotlight effects */}
                <div className="absolute top-0 left-1/4 w-64 h-64 bg-accent/5 rounded-full blur-3xl animate-spotlight" />
                <div className="absolute bottom-0 right-1/4 w-48 h-48 bg-accent/3 rounded-full blur-3xl animate-spotlight" style={{ animationDelay: '1s' }} />
                <div className="absolute top-1/2 left-0 w-32 h-32 bg-accent/3 rounded-full blur-2xl animate-spotlight" style={{ animationDelay: '0.5s' }} />
                <div className="absolute top-1/2 right-0 w-32 h-32 bg-accent/3 rounded-full blur-2xl animate-spotlight" style={{ animationDelay: '1.5s' }} />
                <div className="card-luxury p-12 relative overflow-hidden">
                  <div className="relative z-10 flex flex-col items-center text-center">
                    {/* Decorative music notes floating */}
                    <div className="absolute top-4 left-8 opacity-10 animate-float">
                      <svg className="w-16 h-16 text-accent" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" /></svg>
                    </div>
                    <div className="absolute bottom-4 right-8 opacity-10 animate-float" style={{ animationDelay: '2s' }}>
                      <svg className="w-12 h-12 text-accent" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" /></svg>
                    </div>
                    {/* Main icon with spotlight glow */}
                    <div className="relative mb-6">
                      <div className="absolute -inset-4 rounded-full bg-accent/5 blur-xl animate-ping" />
                      <div className="relative w-24 h-24 rounded-2xl bg-gradient-to-br from-accent/20 via-accent/10 to-accent/5 flex items-center justify-center mb-2 border border-accent/10 shadow-lg concert-shadow-glow">
                        <svg className="w-12 h-12 text-accent/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M9 18V5l12-2v13" strokeLinecap="round" strokeLinejoin="round" />
                          <circle cx="6" cy="18" r="3" />
                          <circle cx="18" cy="16" r="3" />
                        </svg>
                      </div>
                      {/* Gold accent dots */}
                      <div className="absolute -top-2 -right-2 w-3 h-3 rounded-full bg-accent animate-pulse" />
                      <div className="absolute -bottom-1 -left-1 w-2 h-2 rounded-full bg-accent/60 animate-pulse" style={{ animationDelay: '0.5s' }} />
                    </div>
                    <h3 className="text-2xl font-bold text-text-primary mb-2">Belum ada studio</h3>
                    <p className="text-text-muted text-sm max-w-xs mb-8 leading-relaxed">Tempat musik Anda menunggu untuk menjadi nyata. Buat studio pertama dan mulai menjangkarkan impian musisi.</p>
                    <button onClick={() => setShowCreateModal(true)} className="btn-gold text-sm px-8 py-3 shadow-lg concert-shadow-glow">
                      <span className="flex items-center gap-3">
                        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14" strokeLinecap="round" /></svg>
                        Buat Studio Pertama
                        <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 12h14" strokeLinecap="round" /></svg>
                      </span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-5">
            {studios.map((studio, i) => (
              <div key={studio.id} className={`relative overflow-hidden animate-fade-in-up stagger-${Math.min(i + 1, 8)}`}>
                {/* Card with stage spotlight backgrounds */}
                <div className="absolute -top-24 -right-24 w-48 h-48 bg-accent/[0.03] rounded-full blur-3xl transition-all duration-700 group-hover:bg-accent/[0.06]" />
                <div className="absolute -bottom-16 -left-16 w-36 h-36 bg-accent/[0.02] rounded-full blur-2xl transition-all duration-700 group-hover:bg-accent/[0.04]" />
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[50%] h-[50%] bg-accent/[0.015] rounded-full blur-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-700" />

                <div className="action-card p-5 relative z-10 group">
                  {/* Top gold shimmer line + spotlight */}
                  <div className="absolute top-0 left-4 right-4 h-px bg-gradient-to-r from-transparent via-accent/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-20 bg-accent/[0.04] rounded-full blur-md opacity-0 group-hover:opacity-100 transition-opacity" />

                  {/* Studio Header */}
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-accent/15 via-accent/8 to-accent/5 flex items-center justify-center border border-accent/10 shadow-inner concert-shadow relative overflow-hidden">
                        <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-accent/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                        <svg className="relative w-5 h-5 text-accent/70" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                          <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" strokeLinecap="round" strokeLinejoin="round" />
                          <path d="M9 22V12h6v10" strokeLinecap="round" strokeLinejoin="round" />
                        </svg>
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-text-primary font-semibold text-base leading-tight">{studio.name}</h3>
                          {studio.is_verified && (
                            <svg className="w-3.5 h-3.5 text-accent/60 flex-shrink-0" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                          )}
                        </div>
                        <p className="text-text-muted text-xs mt-0.5 flex items-center gap-1.5">
                          <svg className="w-3 h-3 text-text-muted/60 flex-shrink-0" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a8 8 0 0116 0z" strokeLinecap="round" strokeLinejoin="round" /><circle cx="12" cy="10" r="3" /></svg>
                          {studio.city}, {studio.province}
                        </p>
                      </div>
                    </div>
                    <span className={`badge cursor-pointer ${studio.is_verified ? 'bg-accent/10 text-accent border border-accent/20 hover:bg-accent/15 hover:border-accent/30 shadow-sm' : 'bg-warning/10 text-warning border border-warning/20 hover:bg-warning/15 hover:border-warning/30 shadow-sm'}`}>
                      {studio.is_verified ? (
                        <span className="flex items-center gap-1.5">
                          <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M20 6L9 17l-5-5" strokeLinecap="round" strokeLinejoin="round" /></svg>
                          Terverifikasi
                          <span className="absolute -top-0.5 -right-0.5 w-1.5 h-1.5 rounded-full bg-accent animate-pulse" />
                        </span>
                      ) : (
                        <span className="flex items-center gap-1.5">
                          <svg className="w-3 h-3 animate-pulse" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10" /><path d="M12 6v6l4 2" strokeLinecap="round" /></svg>
                          Menunggu
                        </span>
                      )}
                    </span>
                  </div>

                  {/* Stats row - premium glass with gold accent */}
                  <div className="grid grid-cols-3 gap-2.5 mb-4">
                    <div className="rounded-lg p-3 text-center border border-border/20 bg-surface-light/[0.35] group/stats-hover:hover:bg-surface-light/50 group/stats-hover:hover:border-accent/20 transition-all">
                      <p className="text-text-muted text-[0.55rem] font-semibold uppercase tracking-widest flex items-center justify-center gap-1 mb-1.5">
                        <svg className="w-3 h-3 text-accent/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" strokeLinecap="round" strokeLinejoin="round" /></svg>
                        Ruang
                      </p>
                      <p className="text-xl font-extrabold text-text-primary group/stats-hover:hover:text-accent transition-colors">{studio.rooms_count}</p>
                    </div>
                    <div className="rounded-lg p-3 text-center border border-border/20 bg-surface-light/[0.35] group/stats-hover:hover:bg-surface-light/50 group/stats-hover:hover:border-accent/20 transition-all">
                      <p className="text-text-muted text-[0.55rem] font-semibold uppercase tracking-widest flex items-center justify-center gap-1 mb-1.5">
                        <svg className="w-3 h-3 text-warning/60" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                        Rating
                      </p>
                      <div className="flex items-center justify-center gap-0.5 mt-0.5">
                        <svg className="w-4 h-4 text-warning" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                        <p className="text-xl font-extrabold text-text-primary">{studio.average_rating?.toFixed(1) || '0.0'}</p>
                      </div>
                    </div>
                    <div className="rounded-lg p-3 text-center border border-border/20 bg-surface-light/[0.35] group/stats-hover:hover:bg-surface-light/50 group/stats-hover:hover:border-accent/20 transition-all">
                      <p className="text-text-muted text-[0.55rem] font-semibold uppercase tracking-widest flex items-center justify-center gap-1 mb-1.5">
                        <svg className="w-3 h-3 text-text-muted/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" strokeLinecap="round" strokeLinejoin="round" /></svg>
                        Ulasan
                      </p>
                      <p className="text-xl font-extrabold text-text-primary">{studio.total_reviews}</p>
                    </div>
                  </div>

                  {/* Status bar */}
                  <div className="flex items-center justify-between text-xs mb-3 px-1">
                    <span className="text-text-muted flex items-center gap-2">
                      <span className="relative flex items-center">
                        <span className="w-1.5 h-1.5 rounded-full bg-accent/50 animate-pulse" style={{ animationDuration: '1.5s' }} />
                        <span className="absolute w-1.5 h-1.5 rounded-full bg-accent/30 animate-pulse" style={{ animationDelay: '0.2s', animationDuration: '1.5s' }} />
                        <span className="absolute w-1.5 h-1.5 rounded-full bg-accent/30 animate-pulse" style={{ animationDelay: '0.4s', animationDuration: '1.5s' }} />
                      </span>
                      <span className="ml-1.5 text-[0.62rem] font-medium">{studio.total_reviews} ulasan • {studio.total_reviews > 0 ? 'Berkomentar' : 'Menanti ulasan'}</span>
                    </span>
                    <span className={`badge cursor-pointer ${studio.is_active ? 'bg-accent/10 text-accent border border-accent/20 hover:bg-accent/15 hover:border-accent/30 shadow-sm' : 'bg-danger/10 text-danger border border-danger/20 hover:bg-danger/15 hover:border-danger/30 shadow-sm'}`}>
                      {studio.is_active ? '● Aktif' : '○ Nonaktif'}
                    </span>
                  </div>

                  {/* Subscription status */}
                  {(() => {
                    const badge = subscriptionBadge(studio)
                    const sub = studio.subscription
                    return (
                      <div className={`flex items-center justify-between gap-2 mb-4 px-3 py-2 rounded-lg border text-xs ${
                        !sub || sub.status === 'none'
                          ? 'bg-surface-light/30 border-border/20'
                          : sub.status === 'expired'
                            ? 'bg-danger/[0.06] border-danger/20'
                            : 'bg-success/[0.06] border-success/20'
                      }`}>
                        <span className={`font-medium ${badge.className}`}>{badge.text}</span>
                        {sub && sub.status !== 'none' && (
                          <button onClick={() => handleRenewSubscription(studio)} className="text-accent hover:text-accent-hover hover:underline whitespace-nowrap cursor-pointer flex items-center gap-1">
                            <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 1l4 4-4 4" strokeLinecap="round" strokeLinejoin="round" /><path d="M3 11V9a4 4 0 014-4h14" strokeLinecap="round" strokeLinejoin="round" /><path d="M7 23l-4-4 4-4" strokeLinecap="round" strokeLinejoin="round" /><path d="M21 13v2a4 4 0 01-4 4H3" strokeLinecap="round" strokeLinejoin="round" /></svg>
                            Perpanjang
                          </button>
                        )}
                      </div>
                    )
                  })()}

                  {/* Action Buttons - Concert style */}
                  <div className="flex gap-1.5">
                    <button
                      onClick={() => openImageUpload(studio)}
                      className="flex-1 py-2.5 px-3 rounded-lg bg-accent/10 hover:bg-accent/15 border border-accent/20 hover:border-accent/30 text-accent text-xs font-semibold transition-all hover:shadow-lg hover:shadow-accent/10 active:scale-[0.97] cursor-pointer flex items-center justify-center gap-1.5">
                      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      Gambar
                    </button>
                    <button
                      onClick={() => openEditStudio(studio)}
                      className="flex-1 py-2.5 px-3 rounded-lg bg-surface-light/60 hover:bg-surface-light border border-border/30 text-text-secondary hover:text-text-primary text-xs font-semibold transition-all hover:shadow-md active:scale-[0.97] cursor-pointer">
                      Edit
                    </button>
                    <button
                      onClick={() => openRoomModal(studio)}
                      className="flex-1 py-2.5 px-3 rounded-lg bg-surface-light/60 hover:bg-surface-light border border-border/30 text-text-secondary hover:text-text-primary text-xs font-semibold transition-all hover:shadow-md active:scale-[0.97] cursor-pointer">
                      Ruang
                    </button>
                    <button
                      onClick={() => openFacilityModal(studio)}
                      className="flex-1 py-2.5 px-3 rounded-lg bg-surface-light/60 hover:bg-surface-light border border-border/30 text-text-secondary hover:text-text-primary text-xs font-semibold transition-all hover:shadow-md active:scale-[0.97] cursor-pointer">
                      Fasilitas
                    </button>
                    <button
                      onClick={() => handleDeleteStudio(studio.id)}
                      className="w-10 h-10 rounded-lg bg-danger/10 hover:bg-danger/15 border border-danger/20 hover:border-danger/30 text-danger hover:text-danger/80 transition-all active:scale-90 cursor-pointer flex items-center justify-center shadow-sm">
                      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* ─── Studio Image Upload Modal ─── */}
        {showImageUploadModal && imageStudio && (
          <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 animate-fade-in">
            {/* Modal background glow */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-accent/[0.015] rounded-full blur-3xl" />
            <div className="glass-premium rounded-2xl p-8 w-full max-w-lg mx-4 relative z-10 concert-shadow-glow animate-scale-in max-h-[85vh] overflow-y-auto">
              {/* Modal header */}
              <div className="flex items-center justify-between mb-6 pb-4 border-b border-border/20">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/20 to-accent/5 flex items-center justify-center border border-accent/10 shadow-inner concert-shadow">
                    <svg className="w-4 h-4 text-accent/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  </div>
                  <div>
                    <h2 className="text-lg font-bold text-text-primary">Gambar Studio</h2>
                    <p className="text-text-muted text-xs mt-0.5">Upload foto untuk {imageStudio.name}</p>
                  </div>
                </div>
                <button onClick={() => setShowImageUploadModal(false)} className="w-8 h-8 rounded-lg bg-surface-light/80 hover:bg-surface-light border border-border/50 flex items-center justify-center text-text-muted hover:text-text-primary transition-colors">
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                </button>
              </div>

              <div className="mb-6">
                {/* Gallery header */}
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-text-primary font-semibold text-sm flex items-center gap-2">
                    <svg className="w-4 h-4 text-accent/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    Galeri Foto
                  </h3>
                  <span className="text-text-muted text-xs">{studioImages.length} foto</span>
                </div>
                {studioImages.length === 0 ? (
                  <div className="border-2 border-dashed border-accent/20 rounded-xl p-10 text-center hover:border-accent/30 transition-colors bg-surface-light/[0.2]">
                    {/* Decorative music notes */}
                    <div className="absolute top-4 left-6 opacity-5 animate-float">
                      <svg className="w-8 h-8 text-accent" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" /></svg>
                    </div>
                    <div className="absolute bottom-4 right-6 opacity-5 animate-float" style={{ animationDelay: '1s' }}>
                      <svg className="w-6 h-6 text-accent" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5" /></svg>
                    </div>
                    <div className="relative">
                      <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-accent/10 via-accent/5 to-accent/10 flex items-center justify-center border border-accent/10 concert-shadow">
                        <svg className="w-8 h-8 text-accent/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      </div>
                      <p className="text-text-muted text-sm mb-1">Belum ada gambar studio</p>
                      <p className="text-text-muted/60 text-xs">Tambahkan foto untuk menarik lebih banyak musisi</p>
                    </div>
                  </div>
                ) : (
                  <div className="grid grid-cols-3 gap-3">
                    {studioImages.map((img) => (
                      <div key={img.id} className="relative group rounded-xl overflow-hidden border border-border/30 hover:border-accent/30 transition-all hover:shadow-lg hover:shadow-accent/5">
                        <div className="relative overflow-hidden">
                          <img src={img.url} alt={img.caption || 'Studio'} className="w-full h-20 object-cover transition-transform duration-500 group-hover:scale-110" />
                          <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                          {/* Primary badge */}
                          {img.is_primary && (
                            <div className="absolute top-1.5 left-1.5 flex items-center gap-1 px-1.5 py-0.5 bg-accent/90 text-white text-[0.5rem] font-bold rounded uppercase tracking-wider">
                              <svg className="w-2.5 h-2.5" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                              Utama
                            </div>
                          )}
                          {/* Action buttons */}
                          <div className="absolute bottom-2 right-2 flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button onClick={() => handleSetPrimary(img.id)} className="p-1.5 bg-white/20 hover:bg-white/30 rounded-lg transition-colors" title="Set sebagai utama">
                              <svg className="w-3.5 h-3.5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                            </button>
                            <button onClick={() => handleDeleteStudioImage(img.id)} className="p-1.5 bg-red-500/50 hover:bg-red-500/80 rounded-lg transition-colors text-white" title="Hapus gambar">
                              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2" strokeLinecap="round" strokeLinejoin="round" /></svg>
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <form onSubmit={handleSaveStudioImage} className="space-y-4">
                {/* Upload area */}
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase flex items-center gap-2">
                    <svg className="w-4 h-4 text-accent/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                    Upload Gambar Studio
                  </label>
                  <div className="border-2 border-dashed border-accent/20 rounded-xl p-6 text-center hover:border-accent/30 hover:bg-accent/5 transition-all cursor-pointer relative overflow-hidden group" onClick={() => document.getElementById('studioImageInput')?.click()}>
                    <div className="absolute inset-0 bg-gradient-to-br from-accent/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                    {studioImagePreview ? (
                      <div className="relative">
                        <img src={studioImagePreview} alt="Preview" className="max-h-36 mx-auto object-contain rounded-lg shadow-md" />
                        <button type="button" onClick={(e) => { e.stopPropagation(); setStudioImageFile(null); setStudioImagePreview(null) }} className="absolute -top-2 -right-2 w-6 h-6 bg-text-primary/20 hover:bg-text-primary/30 rounded-full flex items-center justify-center text-text-primary text-xs transition-colors">
                          ✕
                        </button>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center gap-3 py-2">
                        <div className="w-14 h-14 rounded-xl bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center border border-accent/10 concert-shadow">
                          <svg className="w-7 h-7 text-accent/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                        </div>
                        <p className="text-text-muted text-sm font-medium">Klik atau seret gambar ke sini</p>
                        <p className="text-text-muted/50 text-[0.6rem] uppercase tracking-wider">JPG, PNG, WEBP — Maks. 5MB</p>
                      </div>
                    )}
                    <input
                      id="studioImageInput"
                      type="file"
                      accept="image/jpeg,image/png,image/webp"
                      onChange={handleStudioImageChange}
                      className="hidden"
                    />
                  </div>
                </div>

                {/* Caption */}
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Caption (opsional)</label>
                  <input
                    type="text"
                    value={studioImageCaption}
                    onChange={(e) => setStudioImageCaption(e.target.value)}
                    className="input-luxury w-full text-sm"
                    placeholder="Deskripsi singkat gambar..."
                    maxLength={255}
                  />
                </div>

                {/* Set primary toggle */}
                <div className="flex items-center gap-3 p-3 rounded-lg border border-border/20 bg-surface-light/30">
                  <label className="flex items-center gap-2.5 cursor-pointer flex-1">
                    <div className="relative">
                      <input
                        type="checkbox"
                        checked={setPrimary}
                        onChange={(e) => setSetPrimary(e.target.checked)}
                        className="sr-only"
                      />
                      <div className="w-9 h-5 bg-border/60 rounded-full peer-checked:bg-accent/60 transition-colors">
                        <div className="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow peer-checked:translate-x-4 transition-transform" />
                      </div>
                    </div>
                    <span className="text-text-secondary text-sm">Jadikan gambar utama</span>
                  </label>
                  {setPrimary && (
                    <svg className="w-5 h-5 text-accent/60 flex-shrink-0" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                  )}
                </div>

                <div className="divider-gold my-2" />
                <div className="flex gap-3 pt-2">
                  <button type="button" onClick={() => setShowImageUploadModal(false)} className="flex-1 btn-glass text-sm py-2.5 cursor-pointer">Batal</button>
                  <button type="submit" disabled={uploading} className="flex-[2] btn-gold text-sm py-2.5 disabled:opacity-40 shadow-lg concert-shadow-glow">
                    {uploading ? (
                      <span className="flex items-center justify-center gap-2">
                        <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M21 12a9 9 0 11-6.219-8.56" strokeLinecap="round" /></svg>
                        Mengupload...
                      </span>
                    ) : (
                      <span className="flex items-center justify-center gap-2">
                        <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                        Upload Gambar
                      </span>
                    )}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ─── Create Studio Modal ─── */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 animate-fade-in">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-accent/[0.02] rounded-full blur-3xl" />
            <div className="glass-premium rounded-2xl p-8 w-full max-w-md mx-4 relative z-10 luxury-shadow-glow animate-scale-in max-h-[90vh] overflow-y-auto">
              <div className="flex items-center gap-3 mb-6 pb-4 border-b border-border/20">
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-danger/20 to-danger/5 flex items-center justify-center border border-danger/20 shadow-md shadow-danger/10">
                  <svg className="w-4 h-4 text-danger/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 18V5l12-2v13" strokeLinecap="round" strokeLinejoin="round" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                </div>
                <h2 className="text-lg font-semibold text-text-primary">Buat Studio Baru</h2>
              </div>
              <form onSubmit={handleCreateStudio} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Studio *</label>
                  <input type="text" value={formData.name} onChange={(e) => setFormData({ ...formData, name: e.target.value })} className="input-luxury w-full text-sm" required />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Alamat *</label>
                  <input type="text" value={formData.address} onChange={(e) => setFormData({ ...formData, address: e.target.value })} className="input-luxury w-full text-sm" required />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  {/* Province Dropdown */}
                  <div className="space-y-1.5" ref={provinceRef}>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Provinsi *</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={formData.province || provinceQuery}
                        onChange={(e) => {
                          setProvinceQuery(e.target.value)
                          setFormData({ ...formData, province: '', city: '' })
                          setShowProvinceDropdown(true)
                        }}
                        onFocus={() => { setProvinceQuery(''); setShowProvinceDropdown(true) }}
                        placeholder="Pilih provinsi..."
                        className="input-luxury w-full text-sm pr-8"
                        required
                        autoComplete="off"
                      />
                      <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      {showProvinceDropdown && (
                        <div className="absolute top-full left-0 right-0 mt-1 bg-surface border border-border/50 rounded-xl shadow-xl shadow-black/20 z-50 max-h-48 overflow-y-auto">
                          {filteredProvinces.length === 0 ? (
                            <div className="px-3 py-2 text-text-muted text-xs">Tidak ditemukan</div>
                          ) : filteredProvinces.map((p) => (
                            <button key={p.name} type="button" onClick={() => { setFormData({ ...formData, province: p.name, city: '' }); setProvinceQuery(''); setShowProvinceDropdown(false); setCityQuery('') }}
                              className={`w-full text-left px-3 py-2 text-sm hover:bg-accent/10 transition-colors ${formData.province === p.name ? 'text-accent bg-accent/5' : 'text-text-primary'}`}>
                              {p.name}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                  {/* City Dropdown */}
                  <div className="space-y-1.5" ref={cityRef}>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kota *</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={formData.city || cityQuery}
                        onChange={(e) => { setCityQuery(e.target.value); setFormData({ ...formData, city: '' }); setShowCityDropdown(true) }}
                        onFocus={() => { if (formData.province) { setCityQuery(''); setShowCityDropdown(true) } }}
                        placeholder={formData.province ? 'Pilih kota...' : 'Pilih provinsi dulu'}
                        className="input-luxury w-full text-sm pr-8"
                        disabled={!formData.province}
                        required
                        autoComplete="off"
                      />
                      <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      {showCityDropdown && formData.province && (
                        <div className="absolute top-full left-0 right-0 mt-1 bg-surface border border-border/50 rounded-xl shadow-xl shadow-black/20 z-50 max-h-48 overflow-y-auto">
                          {filteredCities.length === 0 ? (
                            <div className="px-3 py-2 text-text-muted text-xs">Tidak ditemukan</div>
                          ) : filteredCities.map((city) => (
                            <button key={city} type="button" onClick={() => { setFormData({ ...formData, city }); setCityQuery(''); setShowCityDropdown(false) }}
                              className={`w-full text-left px-3 py-2 text-sm hover:bg-accent/10 transition-colors ${formData.city === city ? 'text-accent bg-accent/5' : 'text-text-primary'}`}>
                              {city}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Telepon</label>
                  <input type="tel" value={formData.phone} onChange={(e) => setFormData({ ...formData, phone: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
                  <input type="email" value={formData.email} onChange={(e) => setFormData({ ...formData, email: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="divider-gold my-2" />
                <div className="flex gap-3 pt-2">
                  <button type="button" onClick={() => { setShowCreateModal(false); setProvinceQuery(''); setCityQuery('') }} className="flex-1 btn-glass text-sm py-2.5">Batal</button>
                  <button type="submit" disabled={creating} className="flex-[2] btn-gold text-sm py-2.5 disabled:opacity-40">{creating ? 'Membuat...' : 'Buat Studio'}</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ─── Edit Studio Modal ─── */}
        {editStudio && (
          <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 animate-fade-in">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-80 h-80 bg-accent/[0.02] rounded-full blur-3xl" />
            <div className="glass-premium rounded-2xl p-8 w-full max-w-md mx-4 relative z-10 luxury-shadow-glow animate-scale-in max-h-[90vh] overflow-y-auto">
              <div className="flex items-center gap-3 mb-6 pb-4 border-b border-border/20">
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-danger/20 to-danger/5 flex items-center justify-center border border-danger/20 shadow-md shadow-danger/10">
                  <svg className="w-4 h-4 text-danger/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" strokeLinecap="round" strokeLinejoin="round" /><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" strokeLinecap="round" strokeLinejoin="round" /></svg>
                </div>
                <div className="flex-1">
                  <h2 className="text-lg font-semibold text-text-primary">Edit Studio</h2>
                  <p className="text-text-muted text-xs mt-0.5">{editStudio.name}</p>
                </div>
              </div>
              <form onSubmit={handleUpdateStudio} className="space-y-4">
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Studio *</label>
                  <input type="text" value={editForm.name} onChange={(e) => setEditForm({ ...editForm, name: e.target.value })} className="input-luxury w-full text-sm" required />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Alamat</label>
                  <input type="text" value={editForm.address} onChange={(e) => setEditForm({ ...editForm, address: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  {/* Edit Province Dropdown */}
                  <div className="space-y-1.5" ref={editProvinceRef}>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Provinsi</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={editForm.province || editProvinceQuery}
                        onChange={(e) => { setEditProvinceQuery(e.target.value); setEditForm({ ...editForm, province: '', city: '' }); setShowEditProvinceDropdown(true) }}
                        onFocus={() => { setEditProvinceQuery(''); setShowEditProvinceDropdown(true) }}
                        placeholder="Pilih provinsi..."
                        className="input-luxury w-full text-sm pr-8"
                        autoComplete="off"
                      />
                      <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      {showEditProvinceDropdown && (
                        <div className="absolute top-full left-0 right-0 mt-1 bg-surface border border-border/50 rounded-xl shadow-xl shadow-black/20 z-50 max-h-48 overflow-y-auto">
                          {filteredEditProvinces.length === 0 ? (
                            <div className="px-3 py-2 text-text-muted text-xs">Tidak ditemukan</div>
                          ) : filteredEditProvinces.map((p) => (
                            <button key={p.name} type="button" onClick={() => { setEditForm({ ...editForm, province: p.name, city: '' }); setEditProvinceQuery(''); setShowEditProvinceDropdown(false); setEditCityQuery('') }}
                              className={`w-full text-left px-3 py-2 text-sm hover:bg-accent/10 transition-colors cursor-pointer ${editForm.province === p.name ? 'text-accent bg-accent/5' : 'text-text-primary'}`}>
                              {p.name}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                  {/* Edit City Dropdown */}
                  <div className="space-y-1.5" ref={editCityRef}>
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kota</label>
                    <div className="relative">
                      <input
                        type="text"
                        value={editForm.city || editCityQuery}
                        onChange={(e) => { setEditCityQuery(e.target.value); setEditForm({ ...editForm, city: '' }); setShowEditCityDropdown(true) }}
                        onFocus={() => { if (editForm.province) { setEditCityQuery(''); setShowEditCityDropdown(true) } }}
                        placeholder={editForm.province ? 'Pilih kota...' : 'Pilih provinsi dulu'}
                        className="input-luxury w-full text-sm pr-8"
                        disabled={!editForm.province}
                        autoComplete="off"
                      />
                      <svg className="absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-text-muted pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 9l6 6 6-6" strokeLinecap="round" strokeLinejoin="round" /></svg>
                      {showEditCityDropdown && editForm.province && (
                        <div className="absolute top-full left-0 right-0 mt-1 bg-surface border border-border/50 rounded-xl shadow-xl shadow-black/20 z-50 max-h-48 overflow-y-auto">
                          {filteredEditCities.length === 0 ? (
                            <div className="px-3 py-2 text-text-muted text-xs">Tidak ditemukan</div>
                          ) : filteredEditCities.map((city) => (
                            <button key={city} type="button" onClick={() => { setEditForm({ ...editForm, city }); setEditCityQuery(''); setShowEditCityDropdown(false) }}
                              className={`w-full text-left px-3 py-2 text-sm hover:bg-accent/10 transition-colors cursor-pointer ${editForm.city === city ? 'text-accent bg-accent/5' : 'text-text-primary'}`}>
                              {city}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Telepon</label>
                  <input type="tel" value={editForm.phone} onChange={(e) => setEditForm({ ...editForm, phone: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="space-y-1.5">
                  <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Email</label>
                  <input type="email" value={editForm.email} onChange={(e) => setEditForm({ ...editForm, email: e.target.value })} className="input-luxury w-full text-sm" />
                </div>
                <div className="divider-gold my-2" />
                <div className="flex gap-3 pt-2">
                  <button type="button" onClick={() => setEditStudio(null)} className="flex-1 btn-glass text-sm py-2.5 cursor-pointer">Batal</button>
                  <button type="submit" className="flex-[2] btn-gold text-sm py-2.5 cursor-pointer">Simpan Perubahan</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* ─── Room Management Modal ─── */}
        {showRoomModal && selectedStudio && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
            <div className="glass-premium rounded-2xl w-full max-w-lg mx-4 relative z-10 metal-shadow-glow animate-scale-in max-h-[85vh] overflow-hidden flex flex-col">
              {/* Header */}
              <div className="flex items-center justify-between p-6 pb-4 border-b border-border/20">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-danger/20 to-danger/5 flex items-center justify-center border border-danger/20 shadow-md shadow-danger/10">
                    <svg className="w-4 h-4 text-danger/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 18V5l12-2v13" strokeLinecap="round" strokeLinejoin="round" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-text-primary">Ruangan</h2>
                    <p className="text-text-muted text-xs mt-0.5">{selectedStudio.name}</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  {!editingRoom && (
                    <button onClick={openAddRoom} className="btn-gold text-xs py-2 px-4 shadow-md shadow-danger/10">+ Tambah</button>
                  )}
                  <button onClick={() => { setShowRoomModal(false); setSelectedStudio(null); setEditingRoom(null) }}
                    className="w-8 h-8 rounded-lg bg-surface-light border border-border/50 flex items-center justify-center text-text-muted hover:text-text-primary hover:bg-surface-lighter transition-colors text-sm">
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  </button>
                </div>
              </div>

              {/* Content */}
              <div className="flex-1 overflow-y-auto p-6">
                {editingRoom ? (
                  /* ── Edit/Add Room Form ── */
                  <form onSubmit={handleSaveRoom} className="space-y-4">
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Ruangan *</label>
                      <input type="text" value={roomForm.name} onChange={(e) => setRoomForm({ ...roomForm, name: e.target.value })} className="input-luxury w-full text-sm" placeholder="Contoh: Studio A, Recording Room 1" required />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Deskripsi</label>
                      <textarea value={roomForm.description} onChange={(e) => setRoomForm({ ...roomForm, description: e.target.value })} className="input-luxury w-full text-sm min-h-[80px] resize-none" placeholder="Deskripsi singkat tentang ruangan..." rows={3} />
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Kapasitas *</label>
                        <input type="number" value={roomForm.capacity} onChange={(e) => setRoomForm({ ...roomForm, capacity: e.target.value })} className="input-luxury w-full text-sm" min="1" max="100" required />
                      </div>
                      <div className="space-y-1.5">
                        <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Harga/Jam (IDR) *</label>
                        <div className="relative">
                          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-text-muted text-sm">Rp</span>
                          <input type="number" value={roomForm.price_per_hour} onChange={(e) => setRoomForm({ ...roomForm, price_per_hour: e.target.value })} className="input-luxury w-full text-sm pl-8" min="0" placeholder="100000" required />
                        </div>
                      </div>
                    </div>
                    <div className="divider-gold my-2" />
                    <div className="flex gap-3 pt-2">
                      <button type="button" onClick={() => setEditingRoom(null)} className="flex-1 btn-glass text-sm py-2.5">Batal</button>
                      <button type="submit" disabled={roomSaving} className="flex-[2] btn-gold text-sm py-2.5 disabled:opacity-40 shadow-md shadow-accent/10">
                        {roomSaving ? 'Menyimpan...' : editingRoom ? 'Simpan' : 'Tambah Ruangan'}
                      </button>
                    </div>
                  </form>
                ) : (
                  /* ── Room List ── */
                  roomsLoading ? (
                    <div className="flex items-center justify-center py-12">
                      <div className="flex flex-col items-center gap-3">
                        <div className="relative">
                          <div className="w-10 h-10 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                          <div className="absolute inset-0 rounded-full bg-accent/5 animate-ping" />
                        </div>
                        <p className="text-text-muted text-xs">Memuat ruangan...</p>
                      </div>
                    </div>
                  ) : rooms.length === 0 ? (
                    <div className="text-center py-12">
                      <div className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center border border-accent/10">
                        <svg className="w-8 h-8 text-accent/40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M9 18V5l12-2v13" strokeLinecap="round" strokeLinejoin="round" /><circle cx="6" cy="18" r="3" /><circle cx="18" cy="16" r="3" /></svg>
                      </div>
                      <p className="text-text-muted text-sm mb-4">Belum ada ruangan di studio ini</p>
                      <button onClick={openAddRoom} className="btn-gold text-xs py-2 px-5 shadow-md shadow-accent/10 cursor-pointer">+ Tambah Ruangan Pertama</button>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {rooms.map((room) => (
                        <div key={room.id} className="bg-surface-light/50 border border-border/30 rounded-xl p-4 hover:border-accent/20 hover:shadow-lg hover:shadow-accent/5 transition-all group">
                          <div className="flex items-start justify-between mb-2">
                            <div className="flex items-center gap-2.5">
                              <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center border border-accent/10">
                                <svg className="w-4 h-4 text-accent/60" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" strokeLinecap="round" strokeLinejoin="round" /><circle cx="9" cy="7" r="4" /><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75" strokeLinecap="round" strokeLinejoin="round" /></svg>
                              </div>
                              <div>
                                <h3 className="text-text-primary font-semibold text-sm">{room.name}</h3>
                                {room.description && (
                                  <p className="text-text-muted text-xs mt-0.5 line-clamp-1">{room.description}</p>
                                )}
                              </div>
                            </div>
                            <span className={`badge text-[0.6rem] cursor-pointer ${room.is_active ? 'bg-success/10 text-success border border-success/20 hover:bg-success/20' : 'bg-danger/10 text-danger border border-danger/20 hover:bg-danger/20'}`}>
                              {room.is_active ? 'Aktif' : 'Nonaktif'}
                            </span>
                          </div>
                          <div className="flex items-center gap-4 text-xs mb-3">
                            <span className="text-text-secondary flex items-center gap-1">
                              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" strokeLinecap="round" strokeLinejoin="round" /><circle cx="9" cy="7" r="4" /></svg>
                              {room.capacity} orang
                            </span>
                            <span className="text-accent font-semibold flex items-center gap-1">
                              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 1v22M17 5H9.5a3.5 3.5 0 000 7h5a3.5 3.5 0 010 7H6" strokeLinecap="round" strokeLinejoin="round" /></svg>
                              {room.formatted_price || formatCurrency(room.price_per_hour)}/jam
                            </span>
                          </div>
                          <div className="flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                            <button onClick={() => openEditRoom(room)} className="flex-1 btn-glass text-xs py-1.5 cursor-pointer flex items-center justify-center gap-1">
                              <svg className="w-3 h-3" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7" strokeLinecap="round" strokeLinejoin="round" /><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z" strokeLinecap="round" strokeLinejoin="round" /></svg>
                              Edit
                            </button>
                            <button onClick={() => handleDeleteRoom(room.id)} className="px-3 py-1.5 rounded-lg bg-danger/10 hover:bg-danger/20 border border-danger/20 hover:border-danger/30 text-danger hover:text-danger/80 transition-colors text-xs cursor-pointer flex items-center justify-center">
                              <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2" strokeLinecap="round" strokeLinejoin="round" /></svg>
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  )
                )}
              </div>
            </div>
          </div>
        )}

        {/* ─── Image Upload Modal ─── */}
        {showImageUploadModal && imageStudio && (
          <div className="fixed inset-0 bg-black/70 backdrop-blur-md flex items-center justify-center z-50 animate-fade-in">
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[500px] h-[500px] bg-accent/[0.015] rounded-full blur-3xl" />
            <div className="glass-premium rounded-2xl w-full max-w-xl mx-4 relative z-10 metal-shadow-glow animate-scale-in max-h-[85vh] overflow-y-auto">
              {/* Header */}
              <div className="flex items-center gap-3 p-6 pb-4 border-b border-border/20">
                <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-danger/20 to-danger/5 flex items-center justify-center border border-danger/20 shadow-md shadow-danger/10">
                  <svg className="w-4 h-4 text-danger/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                </div>
                <div className="flex-1">
                  <h2 className="text-lg font-semibold text-text-primary">Gambar Studio</h2>
                  <p className="text-text-muted text-xs mt-0.5">{imageStudio.name}</p>
                </div>
                <button onClick={() => setShowImageUploadModal(false)} className="w-8 h-8 rounded-lg bg-surface-light border border-border/50 flex items-center justify-center text-text-muted hover:text-text-primary hover:bg-surface-lighter transition-colors text-sm">
                  <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                </button>
              </div>

              <div className="p-6">
                {/* Image Gallery */}
                <div className="mb-6">
                  {studioImages.length === 0 ? (
                    <div className="border-2 border-dashed border-border/40 rounded-xl p-8 text-center hover:border-accent/30 transition-colors relative overflow-hidden group">
                      <div className="absolute inset-0 bg-gradient-to-br from-accent/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                      <div className="relative">
                        <div className="w-16 h-16 mx-auto mb-3 rounded-2xl bg-gradient-to-br from-accent/10 to-accent/5 flex items-center justify-center border border-accent/10">
                          <svg className="w-8 h-8 text-accent/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" fill="currentColor" /><path d="M21 15l-5-5L5 21" strokeLinecap="round" strokeLinejoin="round" /></svg>
                        </div>
                        <p className="text-text-muted text-sm mb-1">Belum ada gambar studio</p>
                        <p className="text-text-muted/60 text-xs">Upload gambar pertama Anda di bawah</p>
                      </div>
                    </div>
                  ) : (
                    <div className="mb-4 flex items-center justify-between">
                      <h3 className="text-text-primary font-semibold text-sm">Galery Foto</h3>
                      <span className="text-text-muted text-xs">{studioImages.length} gambar</span>
                    </div>
                  )}
                  <div className="grid grid-cols-3 gap-3">
                    {studioImages.map((img) => (
                      <div key={img.id} className="relative group rounded-xl overflow-hidden border border-border/30 hover:border-accent/30 transition-all hover:shadow-lg hover:shadow-accent/5">
                        <img src={img.url} alt={img.caption || 'Studio'} className="w-full h-20 object-cover" loading="lazy" />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end justify-between p-2">
                          <div className="flex items-center gap-1">
                            {img.is_primary && (
                              <span className="px-1.5 py-0.5 bg-accent/90 text-white text-[0.5rem] font-bold rounded uppercase tracking-wider">
                                <svg className="w-3 h-3 inline-block mr-0.5" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                                Utama
                              </span>
                            )}
                            <button onClick={() => handleSetPrimary(img.id)} className="p-1 bg-white/20 hover:bg-white/30 rounded transition-colors" title="Set sebagai utama">
                              <svg className="w-3.5 h-3.5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                            </button>
                          </div>
                          <button onClick={() => handleDeleteStudioImage(img.id)} className="p-1.5 bg-red-500/50 hover:bg-red-500/80 rounded-lg transition-colors text-white" title="Hapus gambar">
                            <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M3 6h18M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a2 2 0 012-2h4a2 2 0 012 2v2" strokeLinecap="round" strokeLinejoin="round" /></svg>
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Upload Form */}
                <form onSubmit={handleSaveStudioImage} className="space-y-4">
                  <div className="space-y-1.5">
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Upload Gambar Studio</label>
                    <div onClick={() => document.getElementById('studioImageInput')?.click()} className="border-2 border-dashed border-border/40 rounded-xl p-5 text-center hover:border-accent/40 hover:bg-accent/5 transition-all cursor-pointer relative overflow-hidden group">
                      <div className="absolute inset-0 bg-gradient-to-br from-accent/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
                      {studioImagePreview ? (
                        <div className="relative">
                          <img src={studioImagePreview} alt="Preview" className="max-h-36 mx-auto object-contain rounded-lg shadow-md" />
                          <button type="button" onClick={(e) => { e.stopPropagation(); setStudioImageFile(null); setStudioImagePreview(null) }} className="absolute -top-2 -right-2 w-6 h-6 bg-text-primary/20 hover:bg-text-primary/30 rounded-full flex items-center justify-center text-text-primary text-xs transition-colors">
                            ✕
                          </button>
                        </div>
                      ) : (
                        <div className="flex flex-col items-center gap-2 py-2">
                          <div className="w-12 h-12 rounded-xl bg-accent/10 flex items-center justify-center border border-accent/10">
                            <svg className="w-6 h-6 text-accent/50" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                          </div>
                          <p className="text-text-muted text-xs">Klik atau seret gambar ke sini</p>
                          <p className="text-text-muted/50 text-[0.6rem]">JPG, PNG, WEBP — Maks. 5MB</p>
                        </div>
                      )}
                      <input
                        id="studioImageInput"
                        type="file"
                        accept="image/jpeg,image/png,image/webp"
                        onChange={handleStudioImageChange}
                        className="hidden"
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Caption (opsional)</label>
                    <input
                      type="text"
                      value={studioImageCaption}
                      onChange={(e) => setStudioImageCaption(e.target.value)}
                      className="input-luxury w-full text-sm"
                      placeholder="Deskripsi singkat gambar..."
                      maxLength={255}
                    />
                  </div>

                  <div className="flex items-center gap-3 p-3 rounded-xl bg-surface-light/30 border border-border/20">
                    <label className="flex items-center gap-2.5 cursor-pointer flex-1">
                      <div className="relative">
                        <input
                          type="checkbox"
                          checked={setPrimary}
                          onChange={(e) => setSetPrimary(e.target.checked)}
                          className="peer sr-only"
                        />
                        <div className="w-9 h-5 bg-border/50 rounded-full peer-checked:bg-accent/60 transition-colors relative">
                          <div className="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow peer-checked:translate-x-4 transition-transform" />
                        </div>
                      </div>
                      <span className="text-text-secondary text-sm">Jadikan gambar utama</span>
                    </label>
                    {setPrimary && (
                      <svg className="w-5 h-5 text-accent/60 flex-shrink-0" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" /></svg>
                    )}
                  </div>

                  <div className="divider-gold my-2" />
                  <div className="flex gap-3 pt-2">
                    <button type="button" onClick={() => setShowImageUploadModal(false)} className="flex-1 btn-glass text-sm py-2.5 cursor-pointer">Batal</button>
                    <button type="submit" disabled={uploading} className="flex-[2] btn-gold text-sm py-2.5 disabled:opacity-40 shadow-lg shadow-accent/10">
                      {uploading ? (
                        <span className="flex items-center justify-center gap-2">
                          <svg className="w-4 h-4 animate-spin" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 12a9 9 0 11-6.219-8.56" strokeLinecap="round" /></svg>
                          Mengupload...
                        </span>
                      ) : 'Upload Gambar'}
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        )}

        {/* ─── Room Management Modal ─── */}
        {showFacilityModal && facilityStudio && (
          <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 animate-fade-in">
            <div className="glass-strong rounded-2xl w-full max-w-lg mx-4 luxury-shadow-lg animate-scale-in max-h-[85vh] overflow-hidden flex flex-col">
              {/* Header */}
              <div className="flex items-center justify-between p-6 pb-4 border-b border-border/20">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-danger/20 to-danger/5 flex items-center justify-center border border-danger/20 shadow-md shadow-danger/10">
                    <svg className="w-4 h-4 text-danger/80" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 12l2 2 4-4M12 2a10 10 0 100 20 10 10 0 000-20z" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  </div>
                  <div>
                    <h2 className="text-lg font-semibold text-text-primary">Fasilitas</h2>
                    <p className="text-text-muted text-xs mt-0.5">{facilityStudio.name}</p>
                  </div>
                </div>
                <div className="flex gap-2">
                  {!facilityFormOpen && (
                    <button onClick={openAddFacility} className="btn-gold text-xs py-2 px-4 shadow-md shadow-accent/10">+ Tambah</button>
                  )}
                  <button onClick={() => { setShowFacilityModal(false); setFacilityStudio(null); setFacilityFormOpen(false); setEditingFacility(null) }}
                    className="w-8 h-8 rounded-lg bg-surface-light border border-border/50 flex items-center justify-center text-text-muted hover:text-text-primary hover:bg-surface-lighter transition-colors text-sm">
                    <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" /></svg>
                  </button>
                </div>
              </div>

              {/* Content */}
              <div className="flex-1 overflow-y-auto p-6">
                {facilityFormOpen ? (
                  /* ── Add/Edit Facility Form ── */
                  <form onSubmit={handleSaveFacility} className="space-y-4">
                    <h3 className="text-text-primary font-semibold text-sm">{editingFacility ? 'Edit Fasilitas' : 'Tambah Fasilitas'}</h3>
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Nama Fasilitas *</label>
                      <input type="text" value={facilityForm.name} onChange={(e) => setFacilityForm({ ...facilityForm, name: e.target.value })} className="input-luxury w-full text-sm" placeholder="Contoh: AC, Parkir Luas, Sound System..." required />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Deskripsi</label>
                      <textarea value={facilityForm.description} onChange={(e) => setFacilityForm({ ...facilityForm, description: e.target.value })} className="input-luxury w-full text-sm min-h-[70px] resize-none" placeholder="Deskripsi singkat fasilitas ini..." rows={3} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Ikon (emoji)</label>
                      <input type="text" value={facilityForm.icon} onChange={(e) => setFacilityForm({ ...facilityForm, icon: e.target.value })} className="input-luxury w-full text-sm" placeholder="Contoh: ❄️ 🅿️ 🔊 (opsional)" maxLength={20} />
                    </div>
                    <div className="space-y-1.5">
                      <label className="text-text-secondary text-xs font-medium tracking-wide uppercase">Gambar Fasilitas</label>
                      <label className="block w-full cursor-pointer">
                        <div className="border-2 border-dashed border-border/60 rounded-xl p-4 text-center hover:border-accent/40 transition-colors">
                          {facilityImagePreview ? (
                            <div className="space-y-2">
                              <img src={facilityImagePreview} alt="Preview" className="w-full h-36 object-cover rounded-lg" />
                              <p className="text-accent text-xs">Klik untuk ganti gambar</p>
                            </div>
                          ) : (
                            <div>
                              <span className="text-2xl block mb-1">📷</span>
                              <p className="text-text-muted text-xs">Klik untuk upload gambar fasilitas (opsional)</p>
                              <p className="text-text-muted/60 text-[0.65rem] mt-0.5">JPG, PNG, WebP atau GIF. Maks 5 MB</p>
                            </div>
                          )}
                        </div>
                        <input type="file" accept="image/jpeg,image/png,image/jpg,image/webp,image/gif" onChange={handleFacilityImageChange} className="hidden" />
                      </label>
                      {facilityImageFile && (
                        <button type="button" onClick={() => { setFacilityImageFile(null); setFacilityImagePreview(editingFacility?.image || null) }}
                          className="text-danger text-xs hover:underline mt-1 cursor-pointer">
                          Hapus gambar
                        </button>
                      )}
                    </div>
                    <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
                      <input type="checkbox" checked={facilityForm.is_active} onChange={(e) => setFacilityForm({ ...facilityForm, is_active: e.target.checked })} className="accent-accent w-4 h-4" />
                      <span className="text-text-secondary text-xs font-medium tracking-wide uppercase">Tampilkan ke pelanggan</span>
                    </label>
                    <div className="flex gap-3 pt-2">
                      <button type="button" onClick={() => { setFacilityFormOpen(false); setEditingFacility(null) }} className="flex-1 btn-glass text-sm py-2.5 cursor-pointer">Batal</button>
                      <button type="submit" disabled={facilitySaving} className="flex-1 btn-gold text-sm py-2.5 disabled:opacity-40 cursor-pointer">
                        {facilitySaving ? 'Menyimpan...' : editingFacility ? 'Simpan' : 'Tambah'}
                      </button>
                    </div>
                  </form>
                ) : facilitiesLoading ? (
                  <div className="flex items-center justify-center py-12">
                    <div className="flex flex-col items-center gap-3">
                      <div className="w-8 h-8 border-2 border-accent/30 border-t-accent rounded-full animate-spin" />
                      <p className="text-text-muted text-xs">Memuat fasilitas...</p>
                    </div>
                  </div>
                ) : facilities.length === 0 ? (
                  <div className="text-center py-12">
                    <span className="text-4xl block mb-3 opacity-40">✨</span>
                    <p className="text-text-muted text-sm mb-4">Belum ada fasilitas</p>
                    <button onClick={openAddFacility} className="btn-gold text-xs py-2 px-5 cursor-pointer">+ Tambah Fasilitas</button>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {facilities.map((facility) => (
                      <div key={facility.id} className="bg-surface-light/50 border border-border/30 rounded-xl p-4 hover:border-accent/20 transition-all">
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex items-start gap-3 min-w-0">
                            {facility.image ? (
                              <img src={facility.image} alt={facility.name} className="w-16 h-16 rounded-lg object-cover flex-shrink-0" />
                            ) : (
                              <div className="w-12 h-12 rounded-lg bg-surface-lighter flex items-center justify-center text-2xl flex-shrink-0">
                                {facility.icon || '✨'}
                              </div>
                            )}
                            <div className="min-w-0">
                              <h3 className="text-text-primary font-semibold text-sm flex items-center gap-1.5">
                                {facility.icon && !facility.image && <span>{facility.icon}</span>}
                                <span className="truncate">{facility.name}</span>
                              </h3>
                              {facility.description && (
                                <p className="text-text-muted text-xs mt-0.5 line-clamp-2">{facility.description}</p>
                              )}
                            </div>
                          </div>
                          <span className={`badge text-[0.6rem] ${facility.is_active ? 'bg-success/10 text-success border border-success/20' : 'bg-danger/10 text-danger border border-danger/20'}`}>
                            {facility.is_active ? 'Aktif' : 'Nonaktif'}
                          </span>
                        </div>
                        <div className="flex gap-2">
                          <button onClick={() => openEditFacility(facility)} className="flex-1 btn-glass text-xs py-1.5 cursor-pointer">Edit</button>
                          <button onClick={() => handleDeleteFacility(facility.id)} className="px-3 py-1.5 bg-danger/10 border border-danger/20 rounded-lg text-danger hover:bg-danger/15 transition-colors text-xs cursor-pointer">
                            Hapus
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </AdminLayout>
  )
}
