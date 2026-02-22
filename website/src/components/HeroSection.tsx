"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import Link from "next/link";
import InteractiveGate from "./InteractiveGate";
import { BlurFadeIn, TypeWriter, LineReveal } from "./AnimatedText";

export default function HeroSection() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start start", "end start"],
  });

  const textY = useTransform(scrollYProgress, [0, 1], [0, 120]);
  const opacity = useTransform(scrollYProgress, [0, 0.7], [1, 0]);
  const demoY = useTransform(scrollYProgress, [0, 1], [0, 60]);

  return (
    <section
      ref={ref}
      className="relative min-h-[100svh] flex items-center overflow-hidden pt-20 sm:pt-24 pb-12 sm:pb-16"
    >
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_70%_50%_at_30%_40%,rgba(0,245,255,0.06),transparent)]" />
      <div className="absolute inset-0 bg-[radial-gradient(ellipse_40%_40%_at_80%_20%,rgba(102,153,255,0.04),transparent)]" />
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none select-none">
        <span className="font-mono text-[18vw] sm:text-[22vw] font-bold text-foreground/[0.015] leading-none whitespace-nowrap">
          CW
        </span>
      </div>

      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 w-full">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-16 items-center">
          <motion.div style={{ y: textY, opacity }}>
            <motion.div
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="flex items-center gap-3 mb-6 sm:mb-8"
            >
              <LineReveal className="!w-8 shrink-0" delay={0.3} />
              <span className="font-mono text-[10px] sm:text-xs tracking-[0.2em] text-cyan/50">
                <TypeWriter text="v1.0 — LOGIC GATE PUZZLE GAME" speed={30} delay={0.5} cursor={false} />
              </span>
            </motion.div>

            <h1 className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl xl:text-[5.5rem] font-bold tracking-tight leading-[0.88] mb-6 sm:mb-8">
              {["Circuit", "Weaver"].map((word, i) => (
                <motion.span
                  key={word}
                  initial={{ opacity: 0, y: 50, filter: "blur(10px)" }}
                  animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
                  transition={{
                    duration: 0.7,
                    delay: 0.25 + i * 0.15,
                    ease: [0.22, 1, 0.36, 1],
                  }}
                  className={`block ${i === 1 ? "text-gradient" : ""}`}
                >
                  {word}
                </motion.span>
              ))}
            </h1>

            <motion.p
              initial={{ opacity: 0, y: 20, filter: "blur(6px)" }}
              animate={{ opacity: 1, y: 0, filter: "blur(0px)" }}
              transition={{ duration: 0.6, delay: 0.65 }}
              className="text-base sm:text-lg md:text-xl text-foreground/35 max-w-md leading-relaxed mb-8 sm:mb-10"
            >
              Wire real logic gates. Build actual circuits. Solve 20 puzzles
              that teach you how 1s and 0s become decisions.{" "}
              <span className="text-foreground/55">No lectures. Just wires.</span>
            </motion.p>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.8 }}
              className="flex flex-col sm:flex-row gap-3 sm:gap-4"
            >
              <Link
                href="/play"
                className="group relative inline-flex items-center justify-center px-6 sm:px-8 py-3.5 sm:py-4 font-mono text-xs sm:text-sm tracking-widest rounded-xl overflow-hidden"
              >
                <div className="absolute inset-0 bg-gradient-to-r from-cyan to-sapphire transition-all duration-300 group-hover:scale-[1.02]" />
                <div className="absolute inset-0 bg-gradient-to-r from-cyan to-sapphire opacity-0 group-hover:opacity-30 blur-xl transition-opacity duration-300" />
                <span className="relative text-midnight font-bold flex items-center gap-2"><svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>PLAY IN BROWSER</span>
              </Link>
              <Link
                href="https://github.com/DevMubarak1/Circuit-Weaver"
                target="_blank"
                className="inline-flex items-center justify-center gap-2 px-6 sm:px-8 py-3.5 sm:py-4 font-mono text-xs sm:text-sm tracking-widest border border-foreground/10 text-foreground/40 rounded-xl hover:border-foreground/25 hover:text-foreground/60 transition-all duration-300"
              >
                <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23a11.509 11.509 0 0 1 3.004-.404c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z"/></svg>VIEW SOURCE
              </Link>
            </motion.div>
          </motion.div>

          <motion.div
            style={{ y: demoY }}
            initial={{ opacity: 0, scale: 0.92 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{
              duration: 0.8,
              delay: 0.4,
              type: "spring",
              stiffness: 80,
              damping: 18,
            }}
            className="order-first lg:order-last"
          >
            <InteractiveGate />
          </motion.div>
        </div>

        <BlurFadeIn delay={1.0} className="mt-12 sm:mt-16 lg:mt-24">
          <div className="flex items-center gap-6 sm:gap-8 md:gap-16 justify-center lg:justify-start">
            {[
              { value: "20", label: "levels" },
              { value: "7", label: "gate types" },
              { value: "4", label: "chapters" },
            ].map((stat) => (
              <div key={stat.label} className="flex items-baseline gap-1.5 sm:gap-2">
                <span className="font-mono text-xl sm:text-2xl md:text-3xl font-bold text-foreground/70">
                  {stat.value}
                </span>
                <span className="font-mono text-[9px] sm:text-xs tracking-wider text-foreground/20">
                  {stat.label}
                </span>
              </div>
            ))}
          </div>
        </BlurFadeIn>
      </div>
    </section>
  );
}
