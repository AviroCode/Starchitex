import { useState } from 'react'
import { api } from '../api/client.js'
import { useAuth } from '../context/AuthContext.jsx'
import Banner from '../components/Banner.jsx'

export default function RegisterPage() {
  const { login } = useAuth()
  const [form, setForm] = useState({ firstName: '', lastName: '', email: '', phone: '', password: '' })
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(false)

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const submit = async (e) => {
    e.preventDefault()
    setBusy(true)
    setError(null)
    try {
      const jwt = await api.registerGuest(form)
      login(jwt, form.email)
    } catch (err) {
      setError(err.message || 'Could not register.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="login-wrap">
      <form className="panel login-card" onSubmit={submit}>
        <h1 className="login-brand">Starchitex</h1>
        <p className="tagline dark">Create a guest account</p>
        <div className="pair">
          <label>First name<input value={form.firstName} onChange={set('firstName')} autoFocus required /></label>
          <label>Last name<input value={form.lastName} onChange={set('lastName')} required /></label>
        </div>
        <label>Email<input type="email" value={form.email} onChange={set('email')} required /></label>
        <label>Phone<input value={form.phone} onChange={set('phone')} /></label>
        <label>Password<input type="password" value={form.password} onChange={set('password')} required minLength={8} /></label>
        {error && <Banner kind="error">{error}</Banner>}
        <button type="submit" disabled={busy}>{busy ? 'Creating account…' : 'Create account'}</button>
        <p className="hint">Already have an account? <a href="/login">Sign in</a></p>
      </form>
    </div>
  )
}
