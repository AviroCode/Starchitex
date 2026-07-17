import StatusBadge from './StatusBadge.jsx'

// The signature element: a room rendered as a brass key tag on the rack.
export default function KeyTag({ room, typeName }) {
  return (
    <div className="key-tag">
      <span className="room-no">{room.roomNumber}</span>
      <span className="floor">Floor {room.floor}</span>
      {typeName && <span className="rtype">{typeName}</span>}
      {room.housekeepingStatus && (
        <span className="key-tag-status"><StatusBadge value={room.housekeepingStatus} /></span>
      )}
    </div>
  )
}
