import { createContext, useContext, useState, useEffect } from 'react'
import { setToken, setUnauthorizedHandler } from '../api/client.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setTok] = useState(null)
  const [username, setUsername] = useState(null)

  useEffect(() => {
    setUnauthorizedHandler(() => { setTok(null); setUsername(null); setToken(null) })
  }, [])

  const login = (jwt, user) => { setToken(jwt); setTok(jwt); setUsername(user) }
  const logout = () => { setToken(null); setTok(null); setUsername(null) }

  return (
    <AuthContext.Provider value={{ token, username, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => useContext(AuthContext)
