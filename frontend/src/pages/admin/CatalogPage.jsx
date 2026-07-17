import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'

export default function CatalogPage({ branches }) {
  const [types, setTypes] = useState([])
  const [services, setServices] = useState([])
  const [rooms, setRooms] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const [typeName, setTypeName] = useState('')
  const [basePrice, setBasePrice] = useState(1000)
  const [capacity, setCapacity] = useState(2)

  const [serviceName, setServiceName] = useState('')
  const [category, setCategory] = useState('')
  const [price, setPrice] = useState(100)

  const [roomBranchId, setRoomBranchId] = useState(branches[0]?.branchId ?? null)
  const [roomNumber, setRoomNumber] = useState('')
  const [floor, setFloor] = useState(1)
  const [roomTypeId, setRoomTypeId] = useState('')

  const loadAll = () => {
    api.roomTypes().then(setTypes).catch((e) => setError(e.message))
    api.services().then(setServices).catch((e) => setError(e.message))
  }
  useEffect(() => { loadAll() }, [])

  useEffect(() => {
    if (roomBranchId == null) return
    api.roomsByBranch(roomBranchId).then(setRooms).catch((e) => setError(e.message))
  }, [roomBranchId])

  const createType = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createRoomType({ typeName, basePrice: Number(basePrice), capacity: Number(capacity) })
      setNotice(`${typeName} added.`)
      setTypeName(''); setBasePrice(1000); setCapacity(2)
      loadAll()
    } catch { setError('Could not create the room type.') }
  }

  const createService = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createService({ serviceName, category, price: Number(price) })
      setNotice(`${serviceName} added.`)
      setServiceName(''); setCategory(''); setPrice(100)
      loadAll()
    } catch { setError('Could not create the service.') }
  }

  const createRoom = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createRoom({
        branchId: roomBranchId,
        roomNumber,
        floor: Number(floor),
        roomTypeId: Number(roomTypeId),
      })
      setNotice(`Room ${roomNumber} added.`)
      setRoomNumber(''); setFloor(1); setRoomTypeId('')
      api.roomsByBranch(roomBranchId).then(setRooms)
    } catch { setError('Could not create the room — that room number may already exist on this branch.') }
  }

  return (
    <section className="page">
      <header className="page-head"><h2>Catalog</h2></header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New room type</h3>
          <form onSubmit={createType} className="res-form">
            <label>Name<input value={typeName} onChange={(e) => setTypeName(e.target.value)} required /></label>
            <div className="pair">
              <label>Base price<input type="number" min="0" value={basePrice} onChange={(e) => setBasePrice(e.target.value)} required /></label>
              <label>Capacity<input type="number" min="1" value={capacity} onChange={(e) => setCapacity(e.target.value)} required /></label>
            </div>
            <button type="submit">Add room type</button>
          </form>

          <h3 style={{ marginTop: '1.2rem' }}>New service</h3>
          <form onSubmit={createService} className="res-form">
            <label>Name<input value={serviceName} onChange={(e) => setServiceName(e.target.value)} required /></label>
            <label>Category<input value={category} onChange={(e) => setCategory(e.target.value)} required /></label>
            <label>Price<input type="number" min="0" value={price} onChange={(e) => setPrice(e.target.value)} required /></label>
            <button type="submit">Add service</button>
          </form>

          <h3 style={{ marginTop: '1.2rem' }}>New room</h3>
          <form onSubmit={createRoom} className="res-form">
            <label>Branch<BranchPicker branches={branches} value={roomBranchId} onChange={setRoomBranchId} /></label>
            <label>Room number<input value={roomNumber} onChange={(e) => setRoomNumber(e.target.value)} required /></label>
            <label>Floor<input type="number" min="0" value={floor} onChange={(e) => setFloor(e.target.value)} required /></label>
            <label>Room type
              <select value={roomTypeId} onChange={(e) => setRoomTypeId(e.target.value)} required>
                <option value="" disabled>Choose a room type</option>
                {types.map((t) => <option key={t.roomTypeId} value={t.roomTypeId}>{t.typeName}</option>)}
              </select>
            </label>
            <button type="submit" disabled={!roomBranchId}>Add room</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>Room types</h3>
          <table className="res-table">
            <thead><tr><th>Name</th><th>Base price</th><th>Capacity</th></tr></thead>
            <tbody>
              {types.map((t) => (
                <tr key={t.roomTypeId}>
                  <td>{t.typeName}</td>
                  <td className="mono">฿ {Number(t.basePrice).toLocaleString()}</td>
                  <td className="mono">{t.capacity}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <h3 style={{ marginTop: '1.4rem' }}>Services</h3>
          <table className="res-table">
            <thead><tr><th>Name</th><th>Category</th><th>Price</th></tr></thead>
            <tbody>
              {services.map((s) => (
                <tr key={s.serviceId}>
                  <td>{s.serviceName}</td>
                  <td>{s.category}</td>
                  <td className="mono">฿ {Number(s.price).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>

          <h3 style={{ marginTop: '1.4rem', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <span>Rooms</span>
            <BranchPicker branches={branches} value={roomBranchId} onChange={setRoomBranchId} />
          </h3>
          <table className="res-table">
            <thead><tr><th>Number</th><th>Floor</th><th>Type</th></tr></thead>
            <tbody>
              {rooms.map((r) => (
                <tr key={r.roomId}>
                  <td className="mono">{r.roomNumber}</td>
                  <td className="mono">{r.floor}</td>
                  <td>{types.find((t) => t.roomTypeId === r.roomTypeId)?.typeName ?? r.roomTypeId}</td>
                </tr>
              ))}
              {rooms.length === 0 && <tr><td colSpan="3" className="empty">No rooms for this branch yet.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
