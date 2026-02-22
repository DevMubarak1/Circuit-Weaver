"use client";

import { motion } from "framer-motion";
import { useState } from "react";
import { SplitHeading, BlurFadeIn, CountUp } from "./AnimatedText";

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.07 },
  },
};

const card = {
  hidden: { opacity: 0, y: 30, filter: "blur(6px)" },
  show: {
    opacity: 1,
    y: 0,
    filter: "blur(0px)",
    transition: { type: "spring" as const, stiffness: 100, damping: 16 },
  },
};

function MiniTruthTable() {
  const [active, setActive] = useState<number | null>(null);

  const rows = [
    { a: false, b: false },
    { a: false, b: true },
    { a: true, b: false },
    { a: true, b: true },
  ];

  return (
    <div className="font-mono text-xs sm:text-sm">
      <div className="grid grid-cols-3 gap-x-4 mb-1.5 px-2">
        <span className="text-foreground/25">A</span>
        <span className="text-foreground/25">B</span>
        <span className="text-emerald/50">OUT</span>
      </div>
      {rows.map((row, i) => {
        const out = row.a && row.b;
        return (
          <div
            key={i}
            onMouseEnter={() => setActive(i)}
            onMouseLeave={() => setActive(null)}
            className={`grid grid-cols-3 gap-x-4 py-1.5 px-2 rounded cursor-default transition-colors duration-150 ${
              active === i ? "bg-emerald/5" : ""
            }`}
          >
            <span className={row.a ? "text-cyan" : "text-foreground/15"}>
              {row.a ? "1" : "0"}
            </span>
            <span className={row.b ? "text-cyan" : "text-foreground/15"}>
              {row.b ? "1" : "0"}
            </span>
            <span
              className={out ? "text-emerald font-bold" : "text-foreground/10"}
            >
              {out ? "1" : "0"}
            </span>
          </div>
        );
      })}
    </div>
  );
}

export default function FeaturesSection() {
  return (
    <section id="features" className="relative py-16 sm:py-24 md:py-32 px-4 sm:px-6">
      <div className="max-w-6xl mx-auto">
        <div className="mb-10 sm:mb-14 max-w-xl">
          <SplitHeading
            as="h2"
            className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight leading-[0.95]"
          >
            {"Not a quiz app.\nA circuit lab."}
          </SplitHeading>
          <BlurFadeIn delay={0.3}>
            <p className="mt-4 sm:mt-5 text-foreground/30 leading-relaxed text-sm sm:text-base">
              Everything you need to understand digital logic — built into a puzzle
              game you actually want to play.
            </p>
          </BlurFadeIn>
        </div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: "-60px" }}
          className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3 md:gap-4"
        >
          <motion.div
            variants={card}
            className="sm:col-span-2 md:col-span-1 md:row-span-2 glass-panel p-6 sm:p-7 md:p-8 flex flex-col justify-between border border-foreground/[0.04] hover:border-foreground/[0.08] transition-colors duration-300 min-h-[180px] sm:min-h-[200px]"
          >
            <p className="text-foreground/45 leading-[1.7] text-[15px]">
              Drag gates onto the board. Draw wires between pins. Watch signals
              flow through your creation in real-time. Every level is a puzzle —
              you build the solution from scratch.
            </p>
            <div className="mt-8">
              <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/15 uppercase">
                hands-on learning
              </span>
            </div>
          </motion.div>

          <motion.div
            variants={card}
            className="glass-panel p-6 md:p-7 flex flex-col justify-between border border-cyan/[0.06] hover:border-cyan/[0.15] transition-colors duration-300 group min-h-[160px]"
          >
            <span className="font-mono text-4xl sm:text-5xl md:text-6xl font-bold text-cyan/70 group-hover:text-cyan transition-colors duration-300">
              <CountUp value={20} delay={0.2} />
            </span>
            <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/20 uppercase">
              levels
            </span>
          </motion.div>

          <motion.div
            variants={card}
            className="glass-panel p-6 md:p-7 flex flex-col justify-between border border-pink/[0.06] hover:border-pink/[0.15] transition-colors duration-300 group min-h-[160px]"
          >
            <span className="font-mono text-4xl sm:text-5xl md:text-6xl font-bold text-pink/70 group-hover:text-pink transition-colors duration-300">
              <CountUp value={7} delay={0.35} />
            </span>
            <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/20 uppercase">
              gate types
            </span>
          </motion.div>

          <motion.div
            variants={card}
            className="sm:col-span-2 glass-panel p-5 sm:p-6 md:p-8 flex flex-col sm:flex-row sm:items-center gap-4 sm:gap-6 border border-emerald/[0.06] hover:border-emerald/[0.12] transition-colors duration-300 min-h-[140px] sm:min-h-[160px]"
          >
            <div className="flex-1">
              <h3 className="text-lg font-bold text-foreground/75 mb-1">
                Live truth tables
              </h3>
              <p className="text-sm text-foreground/25 leading-relaxed">
                See exactly how inputs map to outputs. Hover a row to highlight
                the signal path.
              </p>
            </div>
            <div className="hidden sm:block shrink-0">
              <MiniTruthTable />
            </div>
          </motion.div>

          <motion.div
            variants={card}
            className="glass-panel p-6 flex flex-col justify-between border border-gold/[0.06] hover:border-gold/[0.15] transition-colors duration-300 min-h-[140px]"
          >
            <div className="flex gap-0.5">
              {[1, 2, 3].map((s) => (
                <motion.span
                  key={s}
                  className="text-xl text-gold/70"
                  initial={{ opacity: 0, scale: 0 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true }}
                  transition={{
                    delay: 0.3 + s * 0.08,
                    type: "spring" as const,
                    stiffness: 250,
                  }}
                >
                  ★
                </motion.span>
              ))}
            </div>
            <div>
              <span className="text-sm text-foreground/35 block">
                Efficiency scoring
              </span>
              <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/15 uppercase">
                fewer gates = more stars
              </span>
            </div>
          </motion.div>

          <motion.div
            variants={card}
            className="glass-panel p-6 flex flex-col justify-between border border-violet/[0.06] hover:border-violet/[0.15] transition-colors duration-300 min-h-[140px]"
          >
            <span className="font-mono text-lg text-violet/50">⌘Z</span>
            <div>
              <span className="text-sm text-foreground/35 block">
                Full undo & redo
              </span>
              <span className="font-mono text-[10px] tracking-[0.25em] text-foreground/15 uppercase">
                experiment freely
              </span>
            </div>
          </motion.div>

          <motion.div
            variants={card}
            className="sm:col-span-2 md:col-span-3 glass-panel px-5 sm:px-7 py-4 sm:py-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 border border-foreground/[0.04] hover:border-foreground/[0.08] transition-colors duration-300"
          >
            <div>
              <span className="text-sm text-foreground/50 font-medium">
                Play anywhere
              </span>
              <span className="text-sm text-foreground/25 ml-2">
                — browser, Android, touch & desktop.
              </span>
            </div>
            <div className="flex items-center gap-4 font-mono text-[10px] tracking-[0.2em] text-foreground/15 uppercase">
              <span>web</span>
              <span className="w-[3px] h-[3px] rounded-full bg-foreground/10" />
              <span>android</span>
              <span className="w-[3px] h-[3px] rounded-full bg-foreground/10" />
              <span>touch</span>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
}
