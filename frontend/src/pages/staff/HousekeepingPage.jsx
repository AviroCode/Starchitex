import { useEffect, useState } from 'react'
import { api } from '../../api/client.js'
import Banner from '../../components/Banner.jsx'
import BranchPicker from '../../components/BranchPicker.jsx'
import StatusBadge from '../../components/StatusBadge.jsx'

const TASK_NEXT = { Pending: 'In Progress', 'In Progress': 'Completed' }
const MAINT_NEXT = { Reported: 'In Progress', 'In Progress': 'Completed' }

export default function HousekeepingPage({ branches, branchId, setBranchId }) {
  const [rooms, setRooms] = useState([])
  const [tasks, setTasks] = useState([])
  const [maint, setMaint] = useState([])
  const [error, setError] = useState(null)
  const [notice, setNotice] = useState(null)

  const [taskRoom, setTaskRoom] = useState('')
  const [taskDesc, setTaskDesc] = useState('')
  const [maintRoom, setMaintRoom] = useState('')
  const [maintPriority, setMaintPriority] = useState('Medium')
  const [maintDesc, setMaintDesc] = useState('')

  const loadAll = async () => {
    try {
      const [allTasks, allMaint] = await Promise.all([api.roomTasks(), api.roomMaintenances()])
      setTasks(allTasks); setMaint(allMaint)
    } catch (e) { setError(e.message) }
  }

  useEffect(() => { loadAll() }, [])
  useEffect(() => {
    if (branchId == null) return
    api.roomsByBranch(branchId).then(setRooms).catch((e) => setError(e.message))
  }, [branchId])

  const roomIds = new Set(rooms.map((r) => r.roomId))
  const roomNo = (id) => rooms.find((r) => r.roomId === id)?.roomNumber ?? id
  const branchTasks = tasks.filter((t) => roomIds.has(t.roomId))
  const branchMaint = maint.filter((m) => roomIds.has(m.roomId))

  const createTask = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createRoomTask({ roomId: Number(taskRoom), description: taskDesc })
      setNotice('Housekeeping task created.')
      setTaskRoom(''); setTaskDesc('')
      loadAll()
    } catch {
      setError('Could not create the task — pick a room and description.')
    }
  }

  const advanceTask = async (t) => {
    const next = TASK_NEXT[t.status]
    if (!next) return
    try {
      await api.updateRoomTask(t.roomtaskId, { ...t, status: next, completedTime: next === 'Completed' ? new Date().toISOString() : t.completedTime })
      loadAll()
    } catch { setError('Could not update the task.') }
  }

  const createMaint = async (e) => {
    e.preventDefault()
    setError(null); setNotice(null)
    try {
      await api.createRoomMaintenance({ roomId: Number(maintRoom), priority: maintPriority, description: maintDesc })
      setNotice('Maintenance report logged.')
      setMaintRoom(''); setMaintDesc('')
      loadAll()
    } catch {
      setError('Could not log the report — pick a room and description.')
    }
  }

  const advanceMaint = async (m) => {
    const next = MAINT_NEXT[m.status]
    if (!next) return
    try {
      await api.updateRoomMaintenance(m.roomMaintenanceId, { ...m, status: next, completionDate: next === 'Completed' ? new Date().toISOString().slice(0, 10) : m.completionDate })
      loadAll()
    } catch { setError('Could not update the report.') }
  }

  return (
    <section className="page">
      <header className="page-head">
        <h2>Housekeeping & Maintenance</h2>
        <BranchPicker branches={branches} value={branchId} onChange={setBranchId} />
      </header>
      {error && <Banner kind="error" onClose={() => setError(null)}>{error}</Banner>}
      {notice && <Banner onClose={() => setNotice(null)}>{notice}</Banner>}

      <div className="two-col">
        <div className="panel">
          <h3>New task</h3>
          <form onSubmit={createTask} className="res-form">
            <label>Room
              <select value={taskRoom} onChange={(e) => setTaskRoom(e.target.value)} required>
                <option value="" disabled>Choose a room</option>
                {rooms.map((r) => <option key={r.roomId} value={r.roomId}>{r.roomNumber}</option>)}
              </select>
            </label>
            <label>Description<input value={taskDesc} onChange={(e) => setTaskDesc(e.target.value)} required /></label>
            <button type="submit">Add task</button>
          </form>
          <h3 style={{ marginTop: '1.2rem' }}>Report maintenance</h3>
          <form onSubmit={createMaint} className="res-form">
            <label>Room
              <select value={maintRoom} onChange={(e) => setMaintRoom(e.target.value)} required>
                <option value="" disabled>Choose a room</option>
                {rooms.map((r) => <option key={r.roomId} value={r.roomId}>{r.roomNumber}</option>)}
              </select>
            </label>
            <label>Priority
              <select value={maintPriority} onChange={(e) => setMaintPriority(e.target.value)}>
                <option>Low</option><option>Medium</option><option>High</option>
              </select>
            </label>
            <label>Description<input value={maintDesc} onChange={(e) => setMaintDesc(e.target.value)} required /></label>
            <button type="submit">Log report</button>
          </form>
        </div>

        <div className="panel panel-grow">
          <h3>Housekeeping tasks</h3>
          <table className="res-table">
            <thead><tr><th>Room</th><th>Description</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {branchTasks.map((t) => (
                <tr key={t.roomtaskId}>
                  <td className="mono">{roomNo(t.roomId)}</td>
                  <td>{t.description}</td>
                  <td><StatusBadge value={t.status} /></td>
                  <td>{TASK_NEXT[t.status] && <button className="mini-btn" onClick={() => advanceTask(t)}>Mark {TASK_NEXT[t.status]}</button>}</td>
                </tr>
              ))}
              {branchTasks.length === 0 && <tr><td colSpan="4" className="empty">No housekeeping tasks for this branch.</td></tr>}
            </tbody>
          </table>

          <h3 style={{ marginTop: '1.4rem' }}>Maintenance reports</h3>
          <table className="res-table">
            <thead><tr><th>Room</th><th>Priority</th><th>Description</th><th>Status</th><th></th></tr></thead>
            <tbody>
              {branchMaint.map((m) => (
                <tr key={m.roomMaintenanceId}>
                  <td className="mono">{roomNo(m.roomId)}</td>
                  <td>{m.priority}</td>
                  <td>{m.description}</td>
                  <td><StatusBadge value={m.status} /></td>
                  <td>{MAINT_NEXT[m.status] && <button className="mini-btn" onClick={() => advanceMaint(m)}>Mark {MAINT_NEXT[m.status]}</button>}</td>
                </tr>
              ))}
              {branchMaint.length === 0 && <tr><td colSpan="5" className="empty">No maintenance reports for this branch.</td></tr>}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  )
}
