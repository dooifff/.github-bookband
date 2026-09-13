import { useEffect, useRef, useState } from 'react'

/**
 * Tombol "Lanjutkan dengan Google" berbasis Google Identity Services (GIS).
 *
 * GIS mengembalikan ID token (response.credential). Token itu dikirim ke
 * backend POST /api/v1/auth/google untuk diverifikasi, bukan diproses di client.
 */

interface GoogleCredentialResponse {
  credential?: string
}

interface GoogleButtonOptions {
  theme?: 'outline' | 'filled_blue' | 'filled_black'
  size?: 'large' | 'medium' | 'small'
  text?: 'signin_with' | 'signup_with' | 'continue_with' | 'signin'
  shape?: 'rectangular' | 'pill' | 'circle' | 'square'
  logo_alignment?: 'left' | 'center'
  width?: number
}

interface GoogleIdentityApi {
  accounts: {
    id: {
      initialize: (config: {
        client_id: string
        callback: (response: GoogleCredentialResponse) => void
      }) => void
      renderButton: (parent: HTMLElement, options: GoogleButtonOptions) => void
    }
  }
}

declare global {
  interface Window {
    google?: GoogleIdentityApi
  }
}

const GIS_SCRIPT_SRC = 'https://accounts.google.com/gsi/client'

let gisScriptPromise: Promise<void> | null = null

function loadGisScript(): Promise<void> {
  if (window.google?.accounts?.id) {
    return Promise.resolve()
  }

  if (gisScriptPromise) {
    return gisScriptPromise
  }

  gisScriptPromise = new Promise<void>((resolve, reject) => {
    const existing = document.querySelector<HTMLScriptElement>(`script[src="${GIS_SCRIPT_SRC}"]`)
    const script = existing ?? document.createElement('script')

    script.addEventListener('load', () => resolve())
    script.addEventListener('error', () => reject(new Error('Gagal memuat Google Sign-In')))

    if (!existing) {
      script.src = GIS_SCRIPT_SRC
      script.async = true
      script.defer = true
      document.head.appendChild(script)
    }
  })

  return gisScriptPromise
}

interface GoogleSignInButtonProps {
  clientId: string
  onCredential: (idToken: string) => void | Promise<void>
  onError?: (message: string) => void
  text?: GoogleButtonOptions['text']
}

export default function GoogleSignInButton({
  clientId,
  onCredential,
  onError,
  text = 'continue_with',
}: GoogleSignInButtonProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const [visible, setVisible] = useState(false)

  // Simpan callback di ref agar tombol tidak dirender ulang setiap render parent.
  const onCredentialRef = useRef(onCredential)
  const onErrorRef = useRef(onError)

  useEffect(() => {
    onCredentialRef.current = onCredential
    onErrorRef.current = onError
  }, [onCredential, onError])

  useEffect(() => {
    let cancelled = false

    if (!clientId) {
      return
    }

    loadGisScript()
      .then(() => {
        if (cancelled || !containerRef.current) return

        const google = window.google

        if (!google?.accounts?.id) {
          throw new Error('Google Sign-In tidak tersedia di browser ini')
        }

        google.accounts.id.initialize({
          client_id: clientId,
          callback: (response) => {
            if (response.credential) {
              void onCredentialRef.current(response.credential)
            } else {
              onErrorRef.current?.('Google tidak mengirimkan kredensial login')
            }
          },
        })

        containerRef.current.innerHTML = ''
        google.accounts.id.renderButton(containerRef.current, {
          theme: 'filled_black',
          size: 'large',
          shape: 'rectangular',
          logo_alignment: 'center',
          text,
          width: Math.min(containerRef.current.clientWidth || 336, 336),
        })

        setVisible(true)
      })
      .catch((error: unknown) => {
        if (cancelled) return
        onErrorRef.current?.(error instanceof Error ? error.message : 'Gagal memuat Google Sign-In')
      })

    return () => {
      cancelled = true
    }
  }, [clientId, text])

  if (!clientId) {
    return null
  }

  return <div ref={containerRef} className={`w-full flex justify-center ${visible ? '' : 'hidden'}`} />
}
