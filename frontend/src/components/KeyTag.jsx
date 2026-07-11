// The signature element: a room rendered as a brass key tag on the rack.
export default function KeyTag({ room, typeName }) {
  return (
    <div className="key-tag">
      <span className="room-no">{room.roomNumber}</span>
      <span className="floor">Floor {room.floor}</span>
      {typeName && <span className="rtype">{typeName}</span>}
    </div>
  )
}
