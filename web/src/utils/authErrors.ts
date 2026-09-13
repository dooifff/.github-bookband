/** Ubah error axios menjadi pesan yang ramah pengguna. */
export function describeAuthError(err: any, fallback: string): string {
  if (!err?.response) {
    if (err?.code === 'ECONNABORTED') {
      return 'Request timeout. Server tidak merespon, coba lagi.'
    }
    return 'Tidak bisa terhubung ke server. Pastikan koneksi internet aktif dan coba lagi.'
  }

  const status = err.response.status
  const data = err.response.data

  if (status === 422) {
    const validationErrors = data?.errors
    if (validationErrors) {
      return Object.values(validationErrors).flat().join('. ')
    }
    return data?.message || fallback
  }

  if (status === 401) return data?.message || fallback
  if (status === 404) return 'API endpoint tidak ditemukan. Hubungi administrator.'
  if (status === 429) return data?.message || 'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.'
  if (status >= 500) return data?.message || 'Terjadi kesalahan pada server. Hubungi administrator.'

  return data?.message || fallback
}
