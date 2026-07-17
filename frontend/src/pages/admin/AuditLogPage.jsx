import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'

export default function AuditLogPage() {
  const [logs, setLogs] = useState([])
  const [error, setError] = useState(null)
  const [tableFilter, setTableFilter] = useState('')

  const load = () => {
    const call = tableFilter ? api.auditLogsByTable(tableFilter) : api.auditLogs()
    call.then(setLogs).catch((e) => setError(e.message))
  }
  useEffect(() => { load() }, [tableFilter])

  return (
    <section className="page">
      <header className="page-head">
        <h2>Audit Log</h2>
        <label className="branch-pick">Filter by table
          <select value={tableFilter} onChange={(e) => setTableFilter(e.target.value)}>
            <option value="">All tables</option>
            <option value="Reservation">Reservation</option>
            <option value="Invoice">Invoice</option>
            <option value="Payment">Payment</option>
            <option value="ServiceRequest">ServiceRequest</option>
          </select>
        </label>
      </header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}

      <div className="panel panel-grow">
        <table className="res-table">
          <thead>
            <tr><th>ID</th><th>Time</th><th>Actor</th><th>Action</th><th>Table</th><th>PK</th><th>Column</th><th>Old</th><th>New</th></tr>
          </thead>
          <tbody>
            {logs.slice().reverse().map((l) => (
              <tr key={l.logId}>
                <td className="mono">{l.logId}</td>
                <td className="mono dim">{l.actionTime}</td>
                <td className="mono">{l.employeeId ?? '—'}</td>
                <td>{l.action}</td>
                <td>{l.tableName}</td>
                <td className="mono">{l.pkOfTable}</td>
                <td>{l.affectedCol ?? '—'}</td>
                <td className="dim">{l.oldValue ?? '—'}</td>
                <td className="dim">{l.newValue ?? '—'}</td>
              </tr>
            ))}
            {logs.length === 0 && <tr><td colSpan="9" className="empty">No audit rows for this filter.</td></tr>}
          </tbody>
        </table>
      </div>
    </section>
  )
}
