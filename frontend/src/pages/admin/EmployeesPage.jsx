import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'

const EMPTY = {
  branchId: '', firstName: '', lastName: '', position: '', gender: 'Female',
  dateOfBirth: '', phone: '', email: '', hireDate: '', employmentStatus: 'Active',
}

export default function EmployeesPage({ branches, roleName }) {
  const [employees, setEmployees] = useState([])
  const [roles, setRoles] = useState([])
  // branches is already loaded by the time this page mounts (Shell only
  // renders routes once its boot fetch is ready) — default to the first
  // branch so the BranchPicker's visual selection and form state agree;
  // otherwise the picker shows a branch selected while the underlying
  // state stays empty, silently keeping "Add employee" disabled.
  const [form, setForm] = useState({ ...EMPTY, branchId: branches[0]?.branchId ?? '' })
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [saving, setSaving] = useState(false)
  const [credsFor, setCredsFor] = useState(null)
  const [credsUsername, setCredsUsername] = useState('')
  const [credsPassword, setCredsPassword] = useState('')
  const [credsRoleId, setCredsRoleId] = useState('')
  const canManage = ['System Administrator', 'Hotel Owner', 'Sales Executive'].includes(roleName)
  const canManageCreds = roleName === 'System Administrator'

  const load = () => api.employees().then(setEmployees).catch((e) => setError(e.message))
  useEffect(() => { load(); api.roles().then(setRoles).catch(() => {}) }, [])

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value })

  const create = async (e) => {
    e.preventDefault()
    setSaving(true); setError(null); setNotice(null)
    try {
      await api.createEmployee({ ...form, branchId: Number(form.branchId) })
      setNotice(`${form.firstName} ${form.lastName} added.`)
      setForm(EMPTY)
      load()
    } catch {
      setError('Could not create the employee — check required fields (email must be unique).')
    } finally {
      setSaving(false)
    }
  }

  const createCreds = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createEmployeeCredentials({
        employeeId: credsFor.employeeId,
        username: credsUsername,
        passwordHash: credsPassword,
        roleId: Number(credsRoleId),
      })
      setNotice(`Login created for ${credsFor.firstName} ${credsFor.lastName}.`)
      setCredsFor(null); setCredsUsername(''); setCredsPassword(''); setCredsRoleId('')
    } catch {
      setError('Could not create credentials — username may already be taken, or this employee already has a login.')
    }
  }

  const branchName = (id) => branches.find((b) => b.branchId === id)?.name ?? id

  return (
    <section className="page">
      <header className="page-head"><h2>Employees</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          {canManage ? (
            <>
              <h3>New employee</h3>
              <form onSubmit={create} className="res-form">
                <label>Branch<BranchPicker branches={branches} value={form.branchId ? Number(form.branchId) : null} onChange={(v) => setForm({ ...form, branchId: v })} /></label>
                <div className="pair">
                  <label>First name<input value={form.firstName} onChange={set('firstName')} required /></label>
                  <label>Last name<input value={form.lastName} onChange={set('lastName')} required /></label>
                </div>
                <label>Position<input value={form.position} onChange={set('position')} required /></label>
                <div className="pair">
                  <label>Gender
                    <select value={form.gender} onChange={set('gender')}>
                      <option>Female</option><option>Male</option><option>Other</option>
                    </select>
                  </label>
                  <label>Date of birth<input type="date" value={form.dateOfBirth} onChange={set('dateOfBirth')} required /></label>
                </div>
                <label>Email<input type="email" value={form.email} onChange={set('email')} required /></label>
                <label>Phone<input value={form.phone} onChange={set('phone')} required /></label>
                <label>Hire date<input type="date" value={form.hireDate} onChange={set('hireDate')} required /></label>
                <button type="submit" disabled={saving || !form.branchId}>{saving ? 'Saving…' : 'Add employee'}</button>
              </form>
            </>
          ) : <Banner>Read-only — only admin-tier roles can add employees.</Banner>}

          {credsFor && canManageCreds && (
            <>
              <h3 style={{ marginTop: '1.2rem' }}>Set login for {credsFor.firstName} {credsFor.lastName}</h3>
              <form onSubmit={createCreds} className="res-form">
                <label>Username<input value={credsUsername} onChange={(e) => setCredsUsername(e.target.value)} required /></label>
                <label>Initial password<input type="text" value={credsPassword} onChange={(e) => setCredsPassword(e.target.value)} required /></label>
                <label>Role
                  <select value={credsRoleId} onChange={(e) => setCredsRoleId(e.target.value)} required>
                    <option value="" disabled>Choose a role</option>
                    {roles.map((r) => <option key={r.roleId} value={r.roleId}>{r.roleName}</option>)}
                  </select>
                </label>
                <button type="submit">Create login</button>
              </form>
            </>
          )}
        </div>

        <div className="panel panel-grow">
          <h3>All employees</h3>
          <table className="res-table">
            <thead><tr><th>ID</th><th>Name</th><th>Branch</th><th>Position</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {employees.map((e) => (
                <tr key={e.employeeId}>
                  <td className="mono">{e.employeeId}</td>
                  <td>{e.firstName} {e.lastName}</td>
                  <td>{branchName(e.branchId)}</td>
                  <td>{e.position}</td>
                  <td>{e.employmentStatus}</td>
                  <td className="actions">{canManageCreds ? <button className="mini-btn" onClick={() => setCredsFor(e)}>Set login</button> : <span className="actions-empty">—</span>}</td>
                </tr>
              ))}
              {employees.length === 0 && <tr><td colSpan="6" className="empty">No employees yet.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
