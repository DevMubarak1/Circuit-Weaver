"use client";

import { motion, useScroll, useTransform } from "framer-motion";
import { useRef } from "react";
import Link from "next/link";
import { SplitHeading, BlurFadeIn } from "./AnimatedText";

export default function CTASection() {
  const ref = useRef(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const scale = useTransform(scrollYProgress, [0, 0.5], [0.96, 1]);
  const opacity = useTransform(scrollYProgress, [0, 0.3], [0, 1]);

  return (
    <section ref={ref} className="py-16 sm:py-24 md:py-40 px-4 sm:px-6">
      <motion.div
        style={{ scale, opacity }}
        className="max-w-4xl mx-auto text-center"
      >
        <SplitHeading
          as="h2"
          className="text-3xl sm:text-4xl md:text-5xl lg:text-7xl font-bold tracking-tight leading-[0.9] mb-6 sm:mb-8"
        >
          {"Ready to wire\nyour first gate?"}
        </SplitHeading>

        <BlurFadeIn delay={0.4}>
          <p className="text-foreground/25 max-w-md mx-auto mb-8 sm:mb-10 leading-relaxed text-sm sm:text-base">
            No downloads required. Play directly in your browser or grab it on
            Android. Start simple, end architecting.
          </p>
        </BlurFadeIn>

        <BlurFadeIn delay={0.5}>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3 sm:gap-4">
            <Link
              href="/play"
              className="group relative inline-flex items-center justify-center px-8 sm:px-10 py-3.5 sm:py-4 font-mono text-xs sm:text-sm tracking-widest rounded-xl overflow-hidden w-full sm:w-auto"
            >
              <div className="absolute inset-0 bg-gradient-to-r from-cyan via-sapphire to-violet transition-all duration-300 group-hover:scale-[1.02]" />
              <div className="absolute inset-0 bg-gradient-to-r from-cyan via-sapphire to-violet opacity-0 group-hover:opacity-30 blur-xl transition-opacity duration-300" />
              <span className="relative text-midnight font-bold flex items-center gap-2"><svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>PLAY NOW</span>
            </Link>
            <Link
              href="https://play.google.com/store"
              target="_blank"
              className="group inline-flex items-center gap-3 px-5 sm:px-6 py-2.5 sm:py-3 bg-white/[0.04] border border-foreground/10 rounded-xl hover:border-foreground/20 hover:bg-white/[0.07] transition-all duration-300 w-full sm:w-auto justify-center"
            >
              <svg className="w-7 h-7 shrink-0" viewBox="0 0 24 24">
                <path d="M3.607 1.818L13.6 12l-9.994 10.182a.996.996 0 0 1-.606-.916V2.734a.996.996 0 0 1 .607-.916z" fill="#4AAEFE"/>
                <path d="M13.6 12L3.607 1.818l11.196 6.467L13.6 12z" fill="#43D66C"/>
                <path d="M3.607 22.182L13.6 12l1.204 3.715L3.607 22.182z" fill="#F33E52"/>
                <path d="M20.927 10.571l-6.124-3.286L13.6 12l1.204 3.715 6.123-3.414a1 1 0 0 0 0-1.73z" fill="#FFC801"/>
              </svg>
              <div className="flex flex-col items-start leading-tight">
                <span className="text-[9px] sm:text-[10px] tracking-[0.15em] text-foreground/30 uppercase font-sans">GET IT ON</span>
                <span className="text-base sm:text-lg font-semibold text-foreground/70 group-hover:text-foreground/90 transition-colors -mt-0.5">Google Play</span>
              </div>
            </Link>
          </div>
        </BlurFadeIn>
      </motion.div>
    </section>
  );
}
