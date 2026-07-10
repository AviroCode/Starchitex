import { createContext, useContext, useState, useEffect } from 'react'
import { setToken, setUnauthorizedHandler } from '../api/client.js'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [token, setTok] = useState('mock-token-12345')
  const [username, setUsername] = useState('reception.bkk')

  useEffect(() => {
    // Disable unauthorized handler
    setUnauthorizedHandler(() => {})
    // Set a fake token
    setToken('mock-token-12345')
    localStorage.setItem('accessToken', 'mock-token-12345')
  }, [])

  const login = (jwt, user) => { 
    console.log('Login:', user)
    setToken(jwt)
    setTok(jwt)
    setUsername(user)
    localStorage.setItem('accessToken', jwt)
  }
  
  const logout = () => { 
    setToken(null)
    setTok(null)
    setUsername(null)
    localStorage.removeItem('accessToken')
  }

  return (
    <AuthContext.Provider value={{ token, username, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) throw new Error('useAuth must be used within AuthProvider')
  return context
}
