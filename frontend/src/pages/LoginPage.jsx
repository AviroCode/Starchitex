import { useState } from 'react'
import { api } from '../api/client.js'
import { useAuth } from '../context/AuthContext.jsx'
import Banner from '../components/Banner.jsx'
import ConfirmDialog from '../components/ConfirmDialog.jsx'

export default function LoginPage() {
  const { login } = useAuth()
  const [username, setUsername] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)
  const [showGoogle, setShowGoogle] = useState(false)
  const [googleEmail, setGoogleEmail] = useState('')
  const [googleBusy, setGoogleBusy] = useState(false)
  const [googleError, setGoogleError] = useState(null)

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

  const submitGoogle = async () => {
    setGoogleBusy(true)
    setGoogleError(null)
    try {
      const jwt = await api.googleLogin(googleEmail.trim())
      login(jwt, googleEmail)
    } catch (err) {
      setGoogleError(err.message || 'No staff account found for that organization email.')
    } finally {
      setGoogleBusy(false)
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
        <button type="button" className="mini-btn" style={{ width: '100%' }} onClick={() => setShowGoogle(true)}>
          Sign in with organization Google
        </button>
        <p className="hint">Demo: reception.bkk / demo1234</p>
        <p className="hint">New guest? <a href="/register">Create an account</a></p>
      </form>

      {showGoogle && (
        <ConfirmDialog
          title="Sign in with organization Google (Simulated)"
          confirmLabel="Continue"
          busy={googleBusy}
          onConfirm={submitGoogle}
          onCancel={() => { setShowGoogle(false); setGoogleError(null) }}
        >
          <p className="hint">
            No real Google sign-in is wired up yet — this stands in for it. Enter your
            organization email and, if it matches a provisioned staff account, you're in.
          </p>
          <label>Organization email
            <input type="email" value={googleEmail} onChange={(e) => setGoogleEmail(e.target.value)} autoFocus required />
          </label>
          {googleError && <Banner kind="error">{googleError}</Banner>}
        </ConfirmDialog>
      )}
    </div>
  )
}
