"use client";

import { motion } from "framer-motion";
import { SplitHeading, BlurFadeIn } from "./AnimatedText";

const chapters = [
  {
    number: 1,
    title: "Foundations",
    levels: "1\u20145",
    gates: ["NOT", "AND"],
    description:
      "Start with the basics. A single inverter. Your first AND gate. Learn how digital signals actually work.",
    color: "#00D9D9",
  },
  {
    number: 2,
    title: "Combinational Logic",
    levels: "6\u201413",
    gates: ["OR", "XOR", "NAND", "NOR", "XNOR"],
    description:
      "The full gate toolkit. Build increasingly complex circuits with multiple gate types working together.",
    color: "#6699FF",
  },
  {
    number: 3,
    title: "Multi-Gate Circuits",
    levels: "14\u201417",
    gates: ["All gates"],
    description:
      "Real problem solving. Chain gates, manage multiple inputs, architect solutions from scratch.",
    color: "#B366FF",
  },
  {
    number: 4,
    title: "Final Exam",
    levels: "18\u201420",
    gates: ["Everything"],
    description:
      "The culmination. Multi-input, multi-output circuits. Prove you\u2019ve mastered digital logic.",
    color: "#FFA733",
  },
];

const container = {
  hidden: {},
  show: {
    transition: { staggerChildren: 0.1 },
  },
};

const item = {
  hidden: { opacity: 0, y: 30 },
  show: {
    opacity: 1,
    y: 0,
    transition: { type: "spring" as const, stiffness: 80, damping: 16 },
  },
};

export default function ChaptersSection() {
  return (
    <section id="chapters" className="py-16 sm:py-24 md:py-32 px-4 sm:px-6">
      <div className="max-w-6xl mx-auto">
        <div className="mb-10 sm:mb-14">
          <SplitHeading
            as="h2"
            className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-bold tracking-tight leading-[0.95]"
          >
            {"4 chapters.\n20 levels."}
          </SplitHeading>
          <BlurFadeIn delay={0.3}>
            <p className="mt-4 sm:mt-5 text-foreground/25 max-w-md leading-relaxed text-sm sm:text-base">
              A carefully designed progression from absolute beginner to certified
              circuit architect.
            </p>
          </BlurFadeIn>
        </div>

        <motion.div
          variants={container}
          initial="hidden"
          whileInView="show"
          viewport={{ once: true, margin: "-60px" }}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4"
        >
          {chapters.map((ch) => (
            <motion.div
              key={ch.number}
              variants={item}
              whileHover={{ y: -4 }}
              transition={{ type: "spring", stiffness: 300, damping: 20 }}
              className="glass-panel p-7 relative overflow-hidden group"
              style={{ borderColor: ch.color + "10" }}
            >
              <span
                className="absolute -top-4 sm:-top-6 -right-1 sm:-right-2 font-mono text-[5rem] sm:text-[7rem] font-bold leading-none select-none pointer-events-none"
                style={{ color: ch.color + "06" }}
              >
                {String(ch.number).padStart(2, "0")}
              </span>

              <div className="relative z-10">
                <span
                  className="font-mono text-[10px] tracking-[0.25em] uppercase"
                  style={{ color: ch.color + "80" }}
                >
                  Chapter {ch.number}
                </span>
                <h3
                  className="text-xl font-bold mt-2 mb-3"
                  style={{ color: ch.color }}
                >
                  {ch.title}
                </h3>
                <p className="text-foreground/30 text-sm leading-relaxed mb-5">
                  {ch.description}
                </p>

                <div className="flex flex-wrap gap-1.5 mb-4">
                  {ch.gates.map((gate) => (
                    <span
                      key={gate}
                      className="px-2 py-0.5 rounded font-mono text-[10px] tracking-wider"
                      style={{
                        backgroundColor: ch.color + "08",
                        color: ch.color + "70",
                        border: `1px solid ${ch.color}12`,
                      }}
                    >
                      {gate}
                    </span>
                  ))}
                </div>

                <span className="font-mono text-[10px] tracking-[0.2em] text-foreground/15 uppercase">
                  Levels {ch.levels}
                </span>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>
    </section>
  );
}
