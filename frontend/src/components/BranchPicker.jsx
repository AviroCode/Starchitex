export default function BranchPicker({ branches, value, onChange }) {
  return (
    <label className="branch-pick">
      Branch
      <select value={value ?? ''} onChange={(e) => onChange(Number(e.target.value))}>
        {branches.map((b) => (
          <option key={b.branchId} value={b.branchId}>{b.name}</option>
        ))}
      </select>
    </label>
  )
}
