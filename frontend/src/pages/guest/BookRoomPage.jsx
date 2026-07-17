import { useEffect, useMemo, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'
import PhotoPlaceholder from '../../components/PhotoPlaceholder.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'
import ConfirmDialog from '../../components/ConfirmDialog.jsx'

const REJECTION_HINT =
  'The database rejected this — likely check-out is not after check-in, or that room is already booked (or out of service) for those dates.'

// Local calendar date (not UTC) so "today" matches what the date picker
// shows the guest, regardless of timezone offset.
const todayISO = () => {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}

export default function BookRoomPage({ branches, guestId }) {
  const today = todayISO()
  const [branchId, setBranchId] = useState(branches[0]?.branchId ?? null)
  const [rooms, setRooms] = useState([])
  const [types, setTypes] = useState([])
  const [outOfServiceRoomIds, setOutOfServiceRoomIds] = useState(new Set())
  const [checkIn, setCheckIn] = useState('')
  const [checkOut, setCheckOut] = useState('')
  const [numGuests, setNumGuests] = useState(1)
  const [specialRequests, setSpecialRequests] = useState('')
  const [floorPref, setFloorPref] = useState('any')
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [booking, setBooking] = useState(null)
  const [pendingRoom, setPendingRoom] = useState(null)

  useEffect(() => {
    api.roomTypes().then(setTypes).catch((e) => setError(e.message))
    // Defense-in-depth: the database itself rejects booking a room with an
    // open maintenance ticket (trg_prevent_booking_maintenance_room) — this
    // just surfaces it up front instead of letting the guest hit that
    // rejection after picking dates.
    api.roomMaintenances().then((tickets) => {
      setOutOfServiceRoomIds(new Set(tickets.filter((t) => t.status !== 'Completed').map((t) => t.roomId)))
    }).catch(() => {})
  }, [])

  useEffect(() => {
    if (branchId == null) return
    api.roomsByBranch(branchId).then(setRooms).catch((e) => setError(e.message))
  }, [branchId])

  const typeInfo = useMemo(() => {
    const m = new Map(types.map((t) => [t.roomTypeId, t]))
    return (id) => m.get(id)
  }, [types])

  const sortedRooms = useMemo(() => {
    const list = rooms.slice()
    if (floorPref === 'low') list.sort((a, b) => (a.floor ?? 0) - (b.floor ?? 0))
    if (floorPref === 'high') list.sort((a, b) => (b.floor ?? 0) - (a.floor ?? 0))
    return list
  }, [rooms, floorPref])

  const fmt = (n) => Number(n).toLocaleString('en-US', { minimumFractionDigits: 0 })

  const nights = checkIn && checkOut ? Math.round((new Date(checkOut) - new Date(checkIn)) / 86400000) : 0

  // Opens the confirm overlay instead of booking instantly — the actual
  // booking only fires from confirmBooking() below.
  const requestBook = (room) => {
    if (!checkIn || !checkOut) { setError('Pick check-in and check-out dates first.'); return }
    if (checkIn < today) { setError('Check-in date can\'t be in the past.'); return }
    if (checkOut <= checkIn) { setError('Check-out date must be after check-in.'); return }
    setError(null); setNotice(null)
    setPendingRoom(room)
  }

  const confirmBooking = async () => {
    const room = pendingRoom
    setBooking(room.roomId)
    try {
      // One atomic call — the reservation and its room assignment either
      // both succeed or both roll back (e.g. if the room got booked or
      // flagged out-of-service between page load and confirming here).
      await api.bookRoom({
        branchId,
        guestId,
        checkInDate: checkIn,
        checkOutDate: checkOut,
        numOfGuests: Number(numGuests),
        specialRequests: specialRequests || null,
        roomId: room.roomId,
      })
      setNotice(`Room ${room.roomNumber} booked for ${checkIn} → ${checkOut}. Find it under "My Reservations".`)
      setSpecialRequests('')
      setPendingRoom(null)
    } catch {
      setError(REJECTION_HINT)
      setPendingRoom(null)
    } finally {
      setBooking(null)
    }
  }

  const branchName = branches.find((b) => b.branchId === branchId)?.name ?? ''

  return (
    <section className="page">
      <header className="page-head">
        <h2>Book a Room — {branchName}</h2>
        <BranchPicker branches={branches} value={branchId} onChange={setBranchId} />
      </header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="panel">
        <h3>Your stay</h3>
        <form className="res-form" onSubmit={(e) => e.preventDefault()}>
          <div className="pair">
            <label>Check-in
              <input type="date" min={today} value={checkIn}
                onChange={(e) => {
                  setCheckIn(e.target.value)
                  if (checkOut && checkOut <= e.target.value) setCheckOut('')
                }} required />
            </label>
            <label>Check-out<input type="date" min={checkIn || today} value={checkOut} onChange={(e) => setCheckOut(e.target.value)} required /></label>
          </div>
          <div className="pair">
            <label>Guests<input type="number" min="1" value={numGuests} onChange={(e) => setNumGuests(e.target.value)} required /></label>
            <label>Prefer floor
              <select value={floorPref} onChange={(e) => setFloorPref(e.target.value)}>
                <option value="any">Any</option>
                <option value="low">Low floor</option>
                <option value="high">High floor</option>
              </select>
            </label>
          </div>
          <label>Special requests<input value={specialRequests} onChange={(e) => setSpecialRequests(e.target.value)} placeholder="e.g. non-smoking, extra pillows" /></label>
        </form>
        <p className="hint">Pick your dates, then choose a room below — the database rejects the booking if that room is already taken, or out of service, for those dates.</p>
      </div>

      <div className="room-grid">
        {sortedRooms.map((r) => {
          const t = typeInfo(r.roomTypeId)
          const oos = outOfServiceRoomIds.has(r.roomId)
          return (
            <div key={r.roomId} className="room-card">
              <PhotoPlaceholder label={`${t?.typeName ?? 'Room'} ${r.roomNumber} — photo coming soon`} />
              <div className="room-card-body">
                <div className="room-card-head">
                  <span className="room-no mono">{r.roomNumber}</span>
                  {t && !oos && (
                    <span className="room-card-price">
                      ฿ {fmt(t.basePrice)}
                      <span className="per-night">per night</span>
                    </span>
                  )}
                  {oos && <StatusBadge value="Out of Service" />}
                </div>
                <span className="rtype">{t?.typeName}</span>
                <span className="dim">Floor {r.floor} · sleeps up to {t?.capacity ?? '—'}</span>
                <button className="mini-btn book-btn" disabled={oos || booking === r.roomId} onClick={() => requestBook(r)}>
                  {oos ? 'Unavailable' : booking === r.roomId ? 'Booking…' : 'Book this room'}
                </button>
              </div>
            </div>
          )
        })}
        {rooms.length === 0 && <p className="empty">No rooms for this branch yet.</p>}
      </div>

      {pendingRoom && (
        <ConfirmDialog
          title="Confirm your booking"
          confirmLabel="Confirm booking"
          busy={booking === pendingRoom.roomId}
          onConfirm={confirmBooking}
          onCancel={() => setPendingRoom(null)}
        >
          <dl>
            <div><dt>Room</dt><dd>{pendingRoom.roomNumber} · {typeInfo(pendingRoom.roomTypeId)?.typeName}</dd></div>
            <div><dt>Dates</dt><dd>{checkIn} → {checkOut}</dd></div>
            <div><dt>Nights</dt><dd>{nights}</dd></div>
            {typeInfo(pendingRoom.roomTypeId) && (
              <div><dt>Total</dt><dd>฿ {fmt(typeInfo(pendingRoom.roomTypeId).basePrice * nights)}</dd></div>
            )}
            <div><dt>Guests</dt><dd>{numGuests}</dd></div>
            {specialRequests && <div><dt>Requests</dt><dd>{specialRequests}</dd></div>}
          </dl>
        </ConfirmDialog>
      )}
    </section>
  )
}
