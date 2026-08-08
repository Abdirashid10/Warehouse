export function ConditionSelect({ value, onChange, disabled = false, label = 'Condition', movementType: _movementType }) {
  return (
    <label className="block text-sm font-medium text-foreground">
      {label}
      <select
        value={value}
        onChange={onChange}
        disabled={disabled}
        className="wms-select mt-1"
      >
        <option value="Available / Good">Available / Good</option>
        <option value="Damaged / Defective">Damaged / Defective</option>
        <option value="Under Inspection">Under Inspection</option>
      </select>
    </label>
  );
}

