import { createContext, useContext, useState, useEffect } from 'react'
import { setToken, setUnauthorizedHandler } from '../api/client.js'

const AuthContext = createContext(null)

const STORAGE_KEY = 'starchitex.auth'

function loadStoredAuth() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : { token: null, username: null }
  } catch {
    return { token: null, username: null }
  }
}

export function AuthProvider({ children }) {
  const stored = loadStoredAuth()
  // Hydrate the fetch wrapper's in-memory token synchronously during render
  // (not in an effect) — children mount and may fire their own data-loading
  // effects before this component's own effects would run, so the token
  // must already be set on api/client.js by then, or the first post-refresh
  // requests would go out with no Authorization header.
  if (stored.token) setToken(stored.token)

  const [token, setTok] = useState(stored.token)
  const [username, setUsername] = useState(stored.username)

  useEffect(() => {
    setUnauthorizedHandler(() => {
      setTok(null); setUsername(null); setToken(null)
      localStorage.removeItem(STORAGE_KEY)
    })
  }, [])

  const login = (jwt, user) => {
    setToken(jwt); setTok(jwt); setUsername(user)
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ token: jwt, username: user }))
  }
  const logout = () => {
    setToken(null); setTok(null); setUsername(null)
    localStorage.removeItem(STORAGE_KEY)
  }

  return (
    <AuthContext.Provider value={{ token, username, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
