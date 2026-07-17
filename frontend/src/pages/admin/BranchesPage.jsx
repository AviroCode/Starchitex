import { useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'

const EMPTY = { name: '', address: '', city: '', province: '', postalCode: '', email: '', phone: '', status: 'Active' }

export default function BranchesPage({ branches, refreshBranches, roleName }) {
  const [form, setForm] = useState(EMPTY)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [saving, setSaving] = useState(false)
  const canManage = roleName === 'System Administrator'

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const create = async (e) => {
    e.preventDefault()
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.createBranch(form)
      setNotice(`${form.name} created.`)
      setForm(EMPTY)
      refreshBranches()
    } catch {
      setError('Could not create the branch — check required fields.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Branches</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}
      {!canManage && <Banner>Read-only — only a System Administrator can create or edit branches.</Banner>}

      <div className="two-col">
        {canManage && (
          <div className="panel">
            <h3>New branch</h3>
            <form onSubmit={create} className="res-form">
              <label>Name<input value={form.name} onChange={set('name')} required /></label>
              <label>Address<input value={form.address} onChange={set('address')} required /></label>
              <div className="pair">
                <label>City<input value={form.city} onChange={set('city')} required /></label>
                <label>Province<input value={form.province} onChange={set('province')} required /></label>
              </div>
              <div className="pair">
                <label>Postal code<input value={form.postalCode} onChange={set('postalCode')} required /></label>
                <label>Status
                  <select value={form.status} onChange={set('status')}>
                    <option>Active</option><option>Inactive</option>
                  </select>
                </label>
              </div>
              <label>Email<input type="email" value={form.email} onChange={set('email')} required /></label>
              <label>Phone<input value={form.phone} onChange={set('phone')} required /></label>
              <button type="submit" disabled={saving}>{saving ? 'Saving…' : 'Create branch'}</button>
            </form>
          </div>
        )}

        <div className="panel panel-grow">
          <h3>All branches</h3>
          <table className="res-table">
            <thead><tr><th>ID</th><th>Name</th><th>City</th><th>Status</th></tr></thead>
            <tbody>
              {branches.map((b) => (
                <tr key={b.branchId}>
                  <td className="mono">{b.branchId}</td>
                  <td>{b.name}</td>
                  <td>{b.city}</td>
                  <td>{b.status}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
