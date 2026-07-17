import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'

export default function MyProfilePage({ guestId }) {
  const [form, setForm] = useState(null)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    api.guestById(guestId).then(setForm).catch((e) => setError(e.message))
  }, [guestId])

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const save = async (e) => {
    e.preventDefault()
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.updateGuest(guestId, form)
      setNotice('Profile updated.')
    } catch {
      setError('The database rejected this — passport number and email must stay unique, and all required fields filled.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>My Profile</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      {form && (
        <div className="panel" style={{ maxWidth: 420 }}>
          <h3>Your details</h3>
          <form onSubmit={save} className="res-form">
            <div className="pair">
              <label>First name<input value={form.firstName} onChange={set('firstName')} required /></label>
              <label>Last name<input value={form.lastName} onChange={set('lastName')} required /></label>
            </div>
            <div className="pair">
              <label>Gender
                <select value={form.gender ?? ''} onChange={set('gender')}>
                  <option>Female</option><option>Male</option><option>Other</option>
                </select>
              </label>
              <label>Date of birth<input type="date" value={form.dateOfBirth ?? ''} onChange={set('dateOfBirth')} required /></label>
            </div>
            <div className="pair">
              <label>Nationality<input value={form.nationality ?? ''} onChange={set('nationality')} required /></label>
              <label>Passport no.<input value={form.passportNumber ?? ''} onChange={set('passportNumber')} required /></label>
            </div>
            <label>Email<input type="email" value={form.email ?? ''} onChange={set('email')} required /></label>
            <label>Phone<input value={form.phoneNumber ?? ''} onChange={set('phoneNumber')} /></label>
            <label>Address<input value={form.address ?? ''} onChange={set('address')} required /></label>
            <button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Save changes'}</button>
          </form>
        </div>
      )}
    </section>
  )
}
