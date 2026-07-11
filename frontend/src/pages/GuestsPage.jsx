import { useState } from 'react'
import { api } from '../api/client.js'
import Banner from '../components/Banner.jsx'

const EMPTY = {
  firstName: '', lastName: '', gender: 'Female', dateOfBirth: '',
  nationality: '', passportNumber: '', phoneNumber: '', email: '', address: '',
}

export default function GuestsPage({ guests, refreshGuests }) {
  const [form, setForm] = useState(EMPTY)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [saving, setSaving] = useState(false)

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const create = async (e) => {
    e.preventDefault()
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.createGuest(form)
      setNotice(`Guest ${form.firstName} ${form.lastName} registered.`)
      setForm(EMPTY)
      refreshGuests()
    } catch {
      // Live schema enforces UNIQUE passport + UNIQUE email (§8).
      setError('The database rejected this guest — passport number and email must be unique, and all required fields filled.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Guests</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>Register guest</h3>
          <form onSubmit={create} className="res-form">
            <div className="pair">
              <label>First name<input value={form.firstName} onChange={set('firstName')} required /></label>
              <label>Last name<input value={form.lastName} onChange={set('lastName')} required /></label>
            </div>
            <div className="pair">
              <label>Gender
                <select value={form.gender} onChange={set('gender')}>
                  <option>Female</option><option>Male</option><option>Other</option>
                </select>
              </label>
              <label>Date of birth<input type="date" value={form.dateOfBirth} onChange={set('dateOfBirth')} required /></label>
            </div>
            <div className="pair">
              <label>Nationality<input value={form.nationality} onChange={set('nationality')} required /></label>
              <label>Passport no.<input value={form.passportNumber} onChange={set('passportNumber')} required /></label>
            </div>
            <label>Email<input type="email" value={form.email} onChange={set('email')} required /></label>
            <label>Phone<input value={form.phoneNumber} onChange={set('phoneNumber')} /></label>
            <label>Address<input value={form.address} onChange={set('address')} required /></label>
            <button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Register guest'}</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>All guests</h3>
          <table className="res-table">
            <thead>
              <tr><th>ID</th><th>Name</th><th>Nationality</th><th>Passport</th><th>Email</th></tr>
            </thead>
            <tbody>
              {guests.map((g) => (
                <tr key={g.guestId}>
                  <td className="mono">{g.guestId}</td>
                  <td>{g.firstName} {g.lastName}</td>
                  <td>{g.nationality}</td>
                  <td className="mono">{g.passportNumber}</td>
                  <td>{g.email}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
