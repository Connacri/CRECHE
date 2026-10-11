import React from 'react';

interface QrCodeDisplayProps {
  value: string;
  size?: number;
  label?: string;
}

export const QrCodeDisplay: React.FC<QrCodeDisplayProps> = ({ value, size = 180, label }) => {
  // Deterministic SVG QR pattern generator based on hash
  const hash = Array.from(value).reduce((acc, char) => (acc * 31 + char.charCodeAt(0)) | 0, 0);
  const gridSize = 21;
  const cellSize = size / gridSize;

  const isModuleFilled = (r: number, c: number) => {
    // Corner finder patterns (7x7)
    const isTopLeft = r < 7 && c < 7;
    const isTopRight = r < 7 && c >= gridSize - 7;
    const isBottomLeft = r >= gridSize - 7 && c < 7;

    if (isTopLeft || isTopRight || isBottomLeft) {
      const lr = isBottomLeft ? r - (gridSize - 7) : r;
      const lc = isTopRight ? c - (gridSize - 7) : c;
      if (lr === 0 || lr === 6 || lc === 0 || lc === 6) return true;
      if (lr >= 2 && lr <= 4 && lc >= 2 && lc <= 4) return true;
      return false;
    }

    // Timing patterns
    if (r === 6 || c === 6) return (r + c) % 2 === 0;

    // Pseudo-random data modules derived deterministically
    const seed = (r * 37 + c * 19 + Math.abs(hash)) % 100;
    return seed > 46;
  };

  const cells = [];
  for (let r = 0; r < gridSize; r++) {
    for (let c = 0; c < gridSize; c++) {
      if (isModuleFilled(r, c)) {
        cells.push(
          <rect
            key={`${r}-${c}`}
            x={c * cellSize}
            y={r * cellSize}
            width={cellSize * 0.94}
            height={cellSize * 0.94}
            rx={cellSize * 0.2}
            className="fill-slate-900"
          />
        );
      }
    }
  }

  return (
    <div className="flex flex-col items-center">
      <div
        className="relative p-4 bg-white rounded-2xl shadow-md border border-slate-200"
        style={{ width: size + 32, height: size + 32 }}
      >
        <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
          {cells}
        </svg>
        {/* Center icon badge */}
        <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
          <div className="w-8 h-8 rounded-lg bg-amber-400 text-white flex items-center justify-center font-bold text-xs shadow-md border-2 border-white">
            🧸
          </div>
        </div>
      </div>
      {label && <span className="mt-2 text-xs font-mono font-medium text-slate-500">{label}</span>}
    </div>
  );
};
