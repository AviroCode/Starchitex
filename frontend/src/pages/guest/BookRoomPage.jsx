import { useEffect, useMemo, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import KeyTag from '../../components/KeyTag.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'

const REJECTION_HINT =
  'The database rejected this — likely check-out is not after check-in, or that room is already booked for those dates.'

export default function BookRoomPage({ branches, guestId }) {
  const [branchId, setBranchId] = useState(branches[0]?.branchId ?? null)
  const [rooms, setRooms] = useState([])
  const [types, setTypes] = useState([])
  const [checkIn, setCheckIn] = useState('')
  const [checkOut, setCheckOut] = useState('')
  const [numGuests, setNumGuests] = useState(1)
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)
  const [booking, setBooking] = useState(null)

  useEffect(() => {
    api.roomTypes().then(setTypes).catch((e) => setError(e.message))
  }, [])

  useEffect(() => {
    if (branchId == null) return
    api.roomsByBranch(branchId).then(setRooms).catch((e) => setError(e.message))
  }, [branchId])

  const typeName = useMemo(() => {
    const m = new Map(types.map((t) => [t.roomTypeId, t.typeName]))
    return (id) => m.get(id)
  }, [types])

  const book = async (room) => {
    if (!checkIn || !checkOut) { setError('Pick check-in and check-out dates first.'); return }
    setError(null); setNotice(null); setBooking(room.roomId)
    try {
      await api.createReservation({
        branchId,
        guestId,
        checkInDate: checkIn,
        checkOutDate: checkOut,
        actualCheckinTime: null,
        actualCheckoutTime: null,
        numOfGuests: Number(numGuests),
        status: 'Pending',
      })
      // createReservation returns a plain confirmation string, not the new
      // row — since this is the only reservation this guest session is
      // creating right now, the highest reservationId in their own list is
      // the one that was just created.
      const mine = await api.reservationsByGuest(guestId)
      const created = mine.reduce((max, r) => (r.reservationId > (max?.reservationId ?? -1) ? r : max), null)
      if (!created) throw new Error('Could not find the new reservation.')
      await api.assignRoomToReservation(created.reservationId, room.roomId)
      setNotice(`Room ${room.roomNumber} booked for ${checkIn} → ${checkOut}. Find it under "My Reservations".`)
    } catch {
      setError(REJECTION_HINT)
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
            <label>Check-in<input type="date" value={checkIn} onChange={(e) => setCheckIn(e.target.value)} required /></label>
            <label>Check-out<input type="date" value={checkOut} onChange={(e) => setCheckOut(e.target.value)} required /></label>
          </div>
          <label>Guests<input type="number" min="1" value={numGuests} onChange={(e) => setNumGuests(e.target.value)} required /></label>
        </form>
        <p className="hint">Pick your dates, then choose a room below — the database rejects the booking if that room is already taken for those dates.</p>
      </div>

      <div className="key-rack">
        {rooms.map((r) => (
          <div key={r.roomId} className="key-tag-wrap">
            <KeyTag room={r} typeName={typeName(r.roomTypeId)} />
            <button className="mini-btn book-btn" disabled={booking === r.roomId} onClick={() => book(r)}>
              {booking === r.roomId ? 'Booking…' : 'Book this room'}
            </button>
          </div>
        ))}
        {rooms.length === 0 && <p className="empty">No rooms for this branch yet.</p>}
      </div>
    </section>
  )
}
