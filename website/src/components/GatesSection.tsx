"use client";

import { motion, AnimatePresence } from "framer-motion";
import { useState } from "react";
import { SplitHeading, BlurFadeIn } from "./AnimatedText";

interface Gate {
  name: string;
  expr: string;
  desc: string;
  color: string;
  inputs: number;
  truthTable: { ins: string[]; out: string }[];
}

const gates: Gate[] = [
  {
    name: "NOT",
    expr: "!A",
    desc: "Inverts the input. If it\u2019s 1, you get 0. If it\u2019s 0, you get 1. The simplest gate \u2014 and the foundation of everything.",
    color: "#6699FF",
    inputs: 1,
    truthTable: [
      { ins: ["0"], out: "1" },
      { ins: ["1"], out: "0" },
    ],
  },
  {
    name: "AND",
    expr: "A \u00b7 B",
    desc: "Output is 1 only when both inputs are 1. Think of it as a strict bouncer \u2014 everyone has to be on the list.",
    color: "#FF3366",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "0" },
      { ins: ["0", "1"], out: "0" },
      { ins: ["1", "0"], out: "0" },
      { ins: ["1", "1"], out: "1" },
    ],
  },
  {
    name: "OR",
    expr: "A + B",
    desc: "Output is 1 when at least one input is 1. The generous gate \u2014 anyone can get through.",
    color: "#33FF80",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "0" },
      { ins: ["0", "1"], out: "1" },
      { ins: ["1", "0"], out: "1" },
      { ins: ["1", "1"], out: "1" },
    ],
  },
  {
    name: "XOR",
    expr: "A \u2295 B",
    desc: "Output is 1 when inputs are different. The contrarian \u2014 it only fires on disagreement.",
    color: "#FFA733",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "0" },
      { ins: ["0", "1"], out: "1" },
      { ins: ["1", "0"], out: "1" },
      { ins: ["1", "1"], out: "0" },
    ],
  },
  {
    name: "NAND",
    expr: "!(A \u00b7 B)",
    desc: "The opposite of AND. Output is 0 only when both inputs are 1. The universal gate \u2014 you can build anything from NANDs alone.",
    color: "#B366FF",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "1" },
      { ins: ["0", "1"], out: "1" },
      { ins: ["1", "0"], out: "1" },
      { ins: ["1", "1"], out: "0" },
    ],
  },
  {
    name: "NOR",
    expr: "!(A + B)",
    desc: "The opposite of OR. Output is 1 only when both inputs are 0. Another universal gate with surprising power.",
    color: "#FF6644",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "1" },
      { ins: ["0", "1"], out: "0" },
      { ins: ["1", "0"], out: "0" },
      { ins: ["1", "1"], out: "0" },
    ],
  },
  {
    name: "XNOR",
    expr: "!(A \u2295 B)",
    desc: "The opposite of XOR. Output is 1 when inputs are the same. The equality checker of the digital world.",
    color: "#FF66AA",
    inputs: 2,
    truthTable: [
      { ins: ["0", "0"], out: "1" },
      { ins: ["0", "1"], out: "0" },
      { ins: ["1", "0"], out: "0" },
      { ins: ["1", "1"], out: "1" },
    ],
  },
];

function GateSymbol({ type, color }: { type: string; color: string }) {
  const w = { stroke: color, strokeWidth: 1.5, opacity: 0.4 };
  const b: React.SVGProps<SVGPathElement> = {
    fill: "none",
    stroke: color,
    strokeWidth: 2,
    strokeLinejoin: "round",
  };

  const symbols: Record<string, React.ReactNode> = {
    NOT: (
      <>
        <line x1="5" y1="40" x2="25" y2="40" {...w} />
        <path d="M25,14 L25,66 L76,40 Z" {...b} />
        <circle cx="83" cy="40" r="5" fill="none" stroke={color} strokeWidth={2} />
        <line x1="88" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    AND: (
      <>
        <line x1="5" y1="28" x2="25" y2="28" {...w} />
        <line x1="5" y1="52" x2="25" y2="52" {...w} />
        <path d="M25,14 L25,66 L52,66 Q86,40 52,14 Z" {...b} />
        <line x1="86" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    OR: (
      <>
        <line x1="5" y1="28" x2="34" y2="28" {...w} />
        <line x1="5" y1="52" x2="34" y2="52" {...w} />
        <path d="M25,14 Q37,40 25,66 Q52,66 86,40 Q52,14 25,14 Z" {...b} />
        <line x1="86" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    XOR: (
      <>
        <line x1="5" y1="28" x2="34" y2="28" {...w} />
        <line x1="5" y1="52" x2="34" y2="52" {...w} />
        <path d="M30,14 Q42,40 30,66 Q56,66 86,40 Q56,14 30,14 Z" {...b} />
        <path d="M22,16 Q34,40 22,64" fill="none" stroke={color} strokeWidth={2} />
        <line x1="86" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    NAND: (
      <>
        <line x1="5" y1="28" x2="25" y2="28" {...w} />
        <line x1="5" y1="52" x2="25" y2="52" {...w} />
        <path d="M25,14 L25,66 L50,66 Q80,40 50,14 Z" {...b} />
        <circle cx="86" cy="40" r="5" fill="none" stroke={color} strokeWidth={2} />
        <line x1="91" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    NOR: (
      <>
        <line x1="5" y1="28" x2="34" y2="28" {...w} />
        <line x1="5" y1="52" x2="34" y2="52" {...w} />
        <path d="M25,14 Q37,40 25,66 Q50,66 80,40 Q50,14 25,14 Z" {...b} />
        <circle cx="86" cy="40" r="5" fill="none" stroke={color} strokeWidth={2} />
        <line x1="91" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
    XNOR: (
      <>
        <line x1="5" y1="28" x2="34" y2="28" {...w} />
        <line x1="5" y1="52" x2="34" y2="52" {...w} />
        <path d="M30,14 Q42,40 30,66 Q54,66 80,40 Q54,14 30,14 Z" {...b} />
        <path d="M22,16 Q34,40 22,64" fill="none" stroke={color} strokeWidth={2} />
        <circle cx="86" cy="40" r="5" fill="none" stroke={color} strokeWidth={2} />
        <line x1="91" y1="40" x2="115" y2="40" {...w} />
      </>
    ),
  };

  return (
    <svg viewBox="0 0 120 80" className="w-32 h-auto">
      {symbols[type]}
    </svg>
  );
}

export default function GatesSection() {
  const [active, setActive] = useState(0);
  const gate = gates[active];

  return (
    <section id="gates" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6">
      <div className="max-w-5xl mx-auto">
        <div className="mb-8 sm:mb-12">
          <SplitHeading
            as="h2"
            className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight leading-[0.95]"
          >
            {"The 7 gates.\nInfinite circuits."}
          </SplitHeading>
        </div>

        {/* Tab bar with layoutId underline */}
        <BlurFadeIn delay={0.2} className="mb-6 sm:mb-8">
          <div className="flex gap-0.5 overflow-x-auto pb-3 -mx-1 scrollbar-none">
            {gates.map((g, i) => (
              <button
                key={g.name}
                onClick={() => setActive(i)}
                className="relative px-3 sm:px-4 md:px-5 py-2.5 font-mono text-xs sm:text-sm tracking-wider whitespace-nowrap"
              >
                <span
                  className={`transition-colors duration-200 ${
                    i === active
                      ? "font-bold"
                      : "text-foreground/25 hover:text-foreground/45"
                  }`}
                  style={{ color: i === active ? g.color : undefined }}
                >
                  {g.name}
                </span>
                {i === active && (
                  <motion.div
                    layoutId="gate-tab-underline"
                    className="absolute bottom-0 left-2 right-2 h-[2px] rounded-full"
                    style={{ backgroundColor: g.color }}
                    transition={{ type: "spring", stiffness: 350, damping: 30 }}
                  />
                )}
              </button>
            ))}
          </div>
        </BlurFadeIn>

        {/* Gate detail panel */}
        <AnimatePresence mode="wait">
          <motion.div
            key={active}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            transition={{ duration: 0.2 }}
            className="glass-panel p-5 sm:p-8 md:p-10"
            style={{ borderColor: gate.color + "12" }}
          >
            <div className="grid grid-cols-1 md:grid-cols-[1fr_auto] gap-6 md:gap-12 items-start">
              <div>
                <div className="flex items-baseline gap-3 sm:gap-4 mb-1">
                  <h3
                    className="text-3xl sm:text-4xl md:text-5xl font-bold"
                    style={{ color: gate.color }}
                  >
                    {gate.name}
                  </h3>
                  <span
                    className="font-mono text-sm sm:text-base md:text-lg"
                    style={{ color: gate.color + "50" }}
                  >
                    {gate.expr}
                  </span>
                </div>
                <p className="text-foreground/35 leading-relaxed max-w-lg mt-3 text-sm sm:text-[15px]">
                  {gate.desc}
                </p>
                <div className="mt-8">
                  <GateSymbol type={gate.name} color={gate.color} />
                </div>
              </div>

              <div className="min-w-[160px]">
                <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/15 uppercase block mb-3">
                  truth table
                </span>
                <table className="font-mono text-sm w-full">
                  <thead>
                    <tr className="border-b border-white/[0.06]">
                      {gate.inputs === 1 ? (
                        <th className="pb-2 pr-6 text-left text-foreground/25 font-normal">
                          A
                        </th>
                      ) : (
                        <>
                          <th className="pb-2 pr-6 text-left text-foreground/25 font-normal">
                            A
                          </th>
                          <th className="pb-2 pr-6 text-left text-foreground/25 font-normal">
                            B
                          </th>
                        </>
                      )}
                      <th
                        className="pb-2 text-left font-normal"
                        style={{ color: gate.color + "80" }}
                      >
                        OUT
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    {gate.truthTable.map((row, i) => (
                      <tr key={i} className="border-b border-white/[0.03]">
                        {row.ins.map((val, j) => (
                          <td key={j} className="py-2 pr-6 text-foreground/30">
                            {val}
                          </td>
                        ))}
                        <td
                          className="py-2 font-bold"
                          style={{
                            color:
                              row.out === "1"
                                ? gate.color
                                : "rgba(255,255,255,0.1)",
                          }}
                        >
                          {row.out}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          </motion.div>
        </AnimatePresence>
      </div>
    </section>
  );
}
