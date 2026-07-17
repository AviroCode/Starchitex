import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'

// Local wall-clock time formatted for a <input type="datetime-local"> min attribute.
const nowLocal = () => {
  const d = new Date()
  d.setSeconds(0, 0)
  d.setMinutes(d.getMinutes() - d.getTimezoneOffset())
  return d.toISOString().slice(0, 16)
}

export default function FacilitiesPage({ branches, branchId, setBranchId }) {
  const [minStart] = useState(nowLocal())
  const [facilities, setFacilities] = useState([])
  const [reservations, setReservations] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const [name, setName] = useState('')
  const [capacity, setCapacity] = useState(10)
  const [location, setLocation] = useState('')

  const [bookFacility, setBookFacility] = useState(null)
  const [bookReservation, setBookReservation] = useState('')
  const [start, setStart] = useState('')
  const [end, setEnd] = useState('')

  const loadFacilities = () => {
    if (branchId == null) return
    api.facilitiesByBranch(branchId).then(setFacilities).catch((e) => setError(e.message))
  }

  useEffect(() => { loadFacilities() }, [branchId])
  useEffect(() => { api.reservations().then(setReservations).catch(() => {}) }, [])

  const createFacility = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createFacility({ branchId, facilityName: name, capacity: Number(capacity), location })
      setNotice(`${name} added.`)
      setName(''); setCapacity(10); setLocation('')
      loadFacilities()
    } catch {
      setError('Could not create the facility.')
    }
  }

  const book = async (e) => {
    e.preventDefault()
    if (start < minStart) { setError('Start time can\'t be in the past.'); return }
    if (end <= start) { setError('End time must be after the start time.'); return }
    setError(null); setNotice(null)
    try {
      await api.createFacilityBooking({
        reservationId: Number(bookReservation),
        facilityId: bookFacility.facilityId,
        startDateTime: start,
        endDateTime: end,
      })
      setNotice(`${bookFacility.facilityName} booked for reservation #${bookReservation}.`)
      setBookFacility(null); setBookReservation(''); setStart(''); setEnd('')
    } catch {
      setError('Could not create the booking — check the time range and reservation.')
    }
  }

  const branchName = branches.find((b) => b.branchId === branchId)?.name ?? ''

  return (
    <section className="page">
      <header className="page-head">
        <h2>Facilities — {branchName}</h2>
        <BranchPicker branches={branches} value={branchId} onChange={setBranchId} />
      </header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New facility</h3>
          <form onSubmit={createFacility} className="res-form">
            <label>Name<input value={name} onChange={(e) => setName(e.target.value)} required /></label>
            <label>Capacity<input type="number" min="1" value={capacity} onChange={(e) => setCapacity(e.target.value)} required /></label>
            <label>Location<input value={location} onChange={(e) => setLocation(e.target.value)} required /></label>
            <button type="submit">Add facility</button>
          </form>

          {bookFacility && (
            <>
              <h3 style={{ marginTop: '1.2rem' }}>Book {bookFacility.facilityName}</h3>
              <form onSubmit={book} className="res-form">
                <label>Reservation
                  <select value={bookReservation} onChange={(e) => setBookReservation(e.target.value)} required>
                    <option value="" disabled>Choose a reservation</option>
                    {reservations.map((r) => <option key={r.reservationId} value={r.reservationId}>#{r.reservationId} — {r.status}</option>)}
                  </select>
                </label>
                <label>Start
                  <input type="datetime-local" min={minStart} value={start}
                    onChange={(e) => {
                      setStart(e.target.value)
                      if (end && end <= e.target.value) setEnd('')
                    }} required />
                </label>
                <label>End<input type="datetime-local" min={start || minStart} value={end} onChange={(e) => setEnd(e.target.value)} required /></label>
                <button type="submit">Confirm booking</button>
              </form>
            </>
          )}
        </div>

        <div className="panel panel-grow">
          <h3>Facilities at this branch</h3>
          <table className="res-table">
            <thead><tr><th>Name</th><th>Capacity</th><th>Location</th><th></th></tr></thead>
            <tbody>
              {facilities.map((f) => (
                <tr key={f.facilityId}>
                  <td>{f.facilityName}</td>
                  <td className="mono">{f.capacity}</td>
                  <td>{f.location}</td>
                  <td><button className="mini-btn" onClick={() => setBookFacility(f)}>Book</button></td>
                </tr>
              ))}
              {facilities.length === 0 && <tr><td colSpan="4" className="empty">No facilities for this branch yet.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
