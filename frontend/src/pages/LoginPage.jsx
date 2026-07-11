import { useState } from 'react'
import { api } from '../api/client.js'
import { useAuth } from '../context/AuthContext.jsx'
import Banner from '../components/Banner.jsx'

export default function LoginPage() {
  const { login } = useAuth()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const jwt = await api.login(username.trim(), password.trim())
      login(jwt, username)
    } catch (err) {
      setError(err.message || 'Wrong username or password.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="login-wrap">
      <form className="panel login-card" onSubmit={submit}>
        <h1 className="login-brand">Starchitex</h1>
        <p className="tagline dark">Front Desk Console</p>
        <label>
          Username
          <input 
            type="text" 
            value={username} 
            onChange={(e) => setUsername(e.target.value)} 
            autoFocus 
            required 
          />
        </label>
        <label>
          Password
          <input 
            type="password"  // This hides the password
            value={password} 
            onChange={(e) => setPassword(e.target.value)} 
            required 
          />
        </label>
        {error && <Banner kind="error">{error}</Banner>}
        <button type="submit" disabled={busy}>
          {busy ? 'Signing in…' : 'Sign in'}
        </button>
        <p className="hint">Demo: reception.bkk / demo1234</p>
      </form>
    </div>
  )
}
