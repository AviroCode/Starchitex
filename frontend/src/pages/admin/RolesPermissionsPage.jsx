import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'

export default function RolesPermissionsPage({ roleName }) {
  const [roles, setRoles] = useState([])
  const [permissions, setPermissions] = useState([])
  const [grants, setGrants] = useState({}) // roleId -> Set(permissionId)
  const [error, setError] = useState(null)
  const [busy, setBusy] = useState(null)
  const canManage = roleName === 'System Administrator'

  const load = async () => {
    try {
      const [r, p] = await Promise.all([api.roles(), api.permissions()])
      setRoles(r); setPermissions(p)
      const pairs = await Promise.all(r.map((role) => api.rolePermissionsForRole(role.roleId)))
      const next = {}
      r.forEach((role, i) => { next[role.roleId] = new Set(pairs[i].map((perm) => perm.permissionId)) })
      setGrants(next)
    } catch (e) { setError(e.message) }
  }
  useEffect(() => { load() }, [])

  const toggle = async (roleId, permissionId) => {
    if (!canManage) return
    const has = grants[roleId]?.has(permissionId)
    setBusy(`${roleId}-${permissionId}`); setError(null)
    try {
      if (has) await api.revokePermission(roleId, permissionId)
      else await api.assignPermission(roleId, permissionId)
      setGrants((g) => {
        const next = new Set(g[roleId])
        has ? next.delete(permissionId) : next.add(permissionId)
        return { ...g, [roleId]: next }
      })
    } catch {
      setError('Could not update that permission.')
    } finally {
      setBusy(null)
    }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Roles & Permissions</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {!canManage && <Banner>Read-only — only a System Administrator can assign or revoke permissions.</Banner>}

      <div className="panel panel-grow" style={{ overflowX: 'auto' }}>
        <table className="res-table matrix">
          <thead>
            <tr>
              <th>Role</th>
              {permissions.map((p) => <th key={p.permissionId} title={p.description}>{p.permissionName}</th>)}
            </tr>
          </thead>
          <tbody>
            {roles.map((r) => (
              <tr key={r.roleId}>
                <td>{r.roleName}</td>
                {permissions.map((p) => {
                  const checked = grants[r.roleId]?.has(p.permissionId) ?? false
                  const key = `${r.roleId}-${p.permissionId}`
                  return (
                    <td key={p.permissionId} className="matrix-cell">
                      <input
                        type="checkbox"
                        checked={checked}
                        disabled={!canManage || busy === key}
                        onChange={() => toggle(r.roleId, p.permissionId)}
                      />
                    </td>
                  )
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
