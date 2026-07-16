import { useEffect, useMemo, useState } from 'react'
import { api } from '../api/client.js'
import Banner from '../components/Banner.jsx'
import KeyTag from '../components/KeyTag.jsx'
import BranchPicker from '../components/BranchPicker.jsx'

export default function RoomsPage({ branches, branchId, setBranchId }) {
  const [rooms, setRooms] = useState([])
  const [types, setTypes] = useState([])
  const [error, setError] = useState(null)

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

  const branchName = branches.find((b) => b.branchId === branchId)?.name ?? ''

  return (
    <section className="page">
      <header className="page-head">
        <h2>Rooms — {branchName}</h2>
        <BranchPicker branches={branches} value={branchId} onChange={setBranchId} />
      </header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      <div className="key-rack">
        {rooms.map((r) => <KeyTag key={r.roomId} room={r} typeName={typeName(r.roomTypeId)} />)}
        {rooms.length === 0 && <p className="empty">No rooms for this branch yet.</p>}
      </div>
    </section>
  )
}
