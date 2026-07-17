import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'

const NEXT = { Pending: 'Completed' }

export default function ServiceRequestsPage() {
  const [requests, setRequests] = useState([])
  const [reservations, setReservations] = useState([])
  const [services, setServices] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const [reservationId, setReservationId] = useState('')
  const [serviceId, setServiceId] = useState('')
  const [description, setDescription] = useState('')

  const load = () => api.serviceRequests().then(setRequests).catch((e) => setError(e.message))

  useEffect(() => {
    load()
    api.reservations().then(setReservations).catch(() => {})
    api.services().then(setServices).catch(() => {})
  }, [])

  const create = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createServiceRequest({ reservationId: Number(reservationId), serviceId: Number(serviceId), description })
      setNotice('Service request created.')
      setReservationId(''); setServiceId(''); setDescription('')
      load()
    } catch {
      setError('Could not create the request — pick a reservation and a service.')
    }
  }

  const complete = async (r) => {
    try {
      await api.updateServiceRequest(r.requestId, { ...r, status: 'Completed' })
      load()
    } catch { setError('Could not update the request.') }
  }

  const cancel = async (r) => {
    try {
      await api.updateServiceRequest(r.requestId, { ...r, status: 'Cancelled' })
      load()
    } catch { setError('Could not cancel the request.') }
  }

  const serviceName = (id) => services.find((s) => s.serviceId === id)?.serviceName ?? id

  return (
    <section className="page">
      <header className="page-head"><h2>Service Requests</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New request</h3>
          <form onSubmit={create} className="res-form">
            <label>Reservation
              <select value={reservationId} onChange={(e) => setReservationId(e.target.value)} required>
                <option value="" disabled>Choose a reservation</option>
                {reservations.map((r) => <option key={r.reservationId} value={r.reservationId}>#{r.reservationId} — {r.status}</option>)}
              </select>
            </label>
            <label>Service
              <select value={serviceId} onChange={(e) => setServiceId(e.target.value)} required>
                <option value="" disabled>Choose a service</option>
                {services.map((s) => <option key={s.serviceId} value={s.serviceId}>{s.serviceName}</option>)}
              </select>
            </label>
            <label>Description<input value={description} onChange={(e) => setDescription(e.target.value)} required /></label>
            <button type="submit">Create request</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>All requests</h3>
          <table className="res-table">
            <thead><tr><th>ID</th><th>Reservation</th><th>Service</th><th>Description</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>
              {requests.slice().reverse().map((r) => (
                <tr key={r.requestId}>
                  <td className="mono">{r.requestId}</td>
                  <td className="mono">#{r.reservationId}</td>
                  <td>{serviceName(r.serviceId)}</td>
                  <td>{r.description}</td>
                  <td><StatusBadge value={r.status} /></td>
                  <td className="actions">
                    {NEXT[r.status] || r.status === 'Pending' ? (
                      <>
                        {NEXT[r.status] && <button className="mini-btn" onClick={() => complete(r)}>Mark Completed</button>}
                        {r.status === 'Pending' && <button className="mini-btn" onClick={() => cancel(r)}>Cancel</button>}
                      </>
                    ) : <span className="actions-empty">—</span>}
                  </td>
                </tr>
              ))}
              {requests.length === 0 && <tr><td colSpan="6" className="empty">No service requests yet.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
