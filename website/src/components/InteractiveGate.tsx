"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

type GateType = "AND" | "OR" | "XOR";

const gateLogic: Record<GateType, (a: boolean, b: boolean) => boolean> = {
  AND: (a, b) => a && b,
  OR: (a, b) => a || b,
  XOR: (a, b) => a !== b,
};

const gatePaths: Record<GateType, React.ReactNode> = {
  AND: (
    <path
      d="M155,65 L155,195 L215,195 Q280,130 215,65 Z"
      fill="none"
      strokeWidth="2.5"
      strokeLinejoin="round"
      stroke="inherit"
    />
  ),
  OR: (
    <path
      d="M155,65 Q172,130 155,195 Q220,195 275,130 Q220,65 155,65 Z"
      fill="none"
      strokeWidth="2.5"
      strokeLinejoin="round"
      stroke="inherit"
    />
  ),
  XOR: (
    <>
      <path
        d="M165,65 Q182,130 165,195 Q230,195 280,130 Q230,65 165,65 Z"
        fill="none"
        strokeWidth="2.5"
        strokeLinejoin="round"
        stroke="inherit"
      />
      <path
        d="M150,65 Q167,130 150,195"
        fill="none"
        strokeWidth="2.5"
        strokeLinecap="round"
        stroke="inherit"
      />
    </>
  ),
};

export default function InteractiveGate() {
  const [inputA, setInputA] = useState(false);
  const [inputB, setInputB] = useState(false);
  const [gateType, setGateType] = useState<GateType>("AND");

  const output = gateLogic[gateType](inputA, inputB);

  const cyan = "#00F5FF";
  const dim = "#1F2430";
  const dimStroke = "#2A3040";
  const dimText = "#445566";

  return (
    <div className="relative">
      {/* Gate type switcher */}
      <div className="flex items-center justify-center gap-1 mb-4">
        {(["AND", "OR", "XOR"] as GateType[]).map((type) => (
          <button
            key={type}
            onClick={() => setGateType(type)}
            className={`relative px-4 py-1.5 font-mono text-xs tracking-wider rounded-lg transition-all duration-200 ${
              gateType === type
                ? "text-cyan"
                : "text-foreground/20 hover:text-foreground/40"
            }`}
          >
            {type}
            {gateType === type && (
              <motion.div
                layoutId="gate-switch"
                className="absolute inset-0 bg-cyan/8 border border-cyan/20 rounded-lg -z-10"
                transition={{ type: "spring", stiffness: 400, damping: 30 }}
              />
            )}
          </button>
        ))}
      </div>

      {/* Circuit SVG */}
      <div className="glass-panel p-4 sm:p-6 md:p-8">
        <svg viewBox="0 0 420 260" className="w-full h-auto" style={{ maxWidth: 500 }}>
          {/* Input A wire */}
          <motion.line
            x1="50" y1="95" x2="155" y2="95"
            strokeWidth="2.5"
            strokeLinecap="round"
            animate={{ stroke: inputA ? cyan : dim }}
            transition={{ duration: 0.12 }}
          />

          {/* Input B wire */}
          <motion.line
            x1="50" y1="165" x2="155" y2="165"
            strokeWidth="2.5"
            strokeLinecap="round"
            animate={{ stroke: inputB ? cyan : dim }}
            transition={{ duration: 0.12 }}
          />

          {/* Output wire */}
          <motion.line
            x1="280" y1="130" x2="370" y2="130"
            strokeWidth="2.5"
            strokeLinecap="round"
            animate={{ stroke: output ? cyan : dim }}
            transition={{ duration: 0.15, delay: 0.12 }}
          />

          {/* Gate body */}
          <AnimatePresence mode="wait">
            <motion.g
              key={gateType}
              initial={{ opacity: 0, scale: 0.92 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.92 }}
              transition={{ duration: 0.15 }}
              style={{ stroke: output ? cyan : dimStroke }}
            >
              {gatePaths[gateType]}
              <motion.text
                x="215"
                y="136"
                textAnchor="middle"
                fontSize="15"
                fontFamily="monospace"
                fontWeight="bold"
                animate={{ fill: output ? cyan : dimText }}
                transition={{ duration: 0.2, delay: 0.08 }}
              >
                {gateType}
              </motion.text>
            </motion.g>
          </AnimatePresence>

          {/* Input A toggle */}
          <g
            onClick={() => setInputA(!inputA)}
            className="cursor-pointer"
            role="button"
            tabIndex={0}
          >
            <motion.circle
              cx="50" cy="95" r="22"
              strokeWidth="2"
              animate={{
                stroke: inputA ? cyan : dimStroke,
                fill: inputA ? "rgba(0,245,255,0.08)" : "rgba(31,36,48,0.4)",
              }}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.92 }}
              transition={{ type: "spring", stiffness: 400, damping: 25 }}
            />
            <motion.text
              x="50" y="101"
              textAnchor="middle"
              fontSize="18"
              fontFamily="monospace"
              fontWeight="bold"
              animate={{ fill: inputA ? cyan : dimText }}
              className="pointer-events-none select-none"
            >
              {inputA ? "1" : "0"}
            </motion.text>
            <text x="50" y="68" textAnchor="middle" fontSize="11" fontFamily="monospace" fill="#556">
              A
            </text>
          </g>

          {/* Input B toggle */}
          <g
            onClick={() => setInputB(!inputB)}
            className="cursor-pointer"
            role="button"
            tabIndex={0}
          >
            <motion.circle
              cx="50" cy="165" r="22"
              strokeWidth="2"
              animate={{
                stroke: inputB ? cyan : dimStroke,
                fill: inputB ? "rgba(0,245,255,0.08)" : "rgba(31,36,48,0.4)",
              }}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.92 }}
              transition={{ type: "spring", stiffness: 400, damping: 25 }}
            />
            <motion.text
              x="50" y="171"
              textAnchor="middle"
              fontSize="18"
              fontFamily="monospace"
              fontWeight="bold"
              animate={{ fill: inputB ? cyan : dimText }}
              className="pointer-events-none select-none"
            >
              {inputB ? "1" : "0"}
            </motion.text>
            <text x="50" y="138" textAnchor="middle" fontSize="11" fontFamily="monospace" fill="#556">
              B
            </text>
          </g>

          {/* Output indicator */}
          <motion.circle
            cx="370" cy="130" r="22"
            strokeWidth="2"
            animate={{
              stroke: output ? cyan : dimStroke,
              fill: output ? "rgba(0,245,255,0.12)" : "rgba(31,36,48,0.4)",
            }}
            transition={{ duration: 0.15, delay: 0.15 }}
          />
          <motion.text
            x="370" y="136"
            textAnchor="middle"
            fontSize="18"
            fontFamily="monospace"
            fontWeight="bold"
            animate={{ fill: output ? cyan : dimText }}
            transition={{ delay: 0.15 }}
            className="pointer-events-none select-none"
          >
            {output ? "1" : "0"}
          </motion.text>
          <text x="370" y="103" textAnchor="middle" fontSize="11" fontFamily="monospace" fill="#556">
            OUT
          </text>

          {/* Signal pulse dots on active wires */}
          {inputA && (
            <motion.circle
              r="3.5"
              fill={cyan}
              initial={{ cx: 55, cy: 95, opacity: 0 }}
              animate={{ cx: [55, 150], cy: 95, opacity: [0, 1, 1, 0] }}
              transition={{ duration: 0.8, repeat: Infinity, repeatDelay: 1.2, ease: "easeInOut" }}
            />
          )}
          {inputB && (
            <motion.circle
              r="3.5"
              fill={cyan}
              initial={{ cx: 55, cy: 165, opacity: 0 }}
              animate={{ cx: [55, 150], cy: 165, opacity: [0, 1, 1, 0] }}
              transition={{ duration: 0.8, repeat: Infinity, repeatDelay: 1.5, ease: "easeInOut" }}
            />
          )}
          {output && (
            <motion.circle
              r="3.5"
              fill={cyan}
              initial={{ cx: 285, cy: 130, opacity: 0 }}
              animate={{ cx: [285, 365], cy: 130, opacity: [0, 1, 1, 0] }}
              transition={{ duration: 0.7, repeat: Infinity, repeatDelay: 1, ease: "easeInOut" }}
            />
          )}
        </svg>

        <p className="text-center font-mono text-[11px] text-foreground/20 mt-3 tracking-wider select-none">
          TAP THE INPUTS TO TOGGLE
        </p>
      </div>
    </div>
  );
}
