"use client";

import { motion, useInView } from "framer-motion";
import { useRef } from "react";

/* ─── SplitHeading ───────────────────────────────────────── */

interface SplitHeadingProps {
  children: string;
  className?: string;
  as?: "h1" | "h2" | "h3" | "h4" | "span";
  delay?: number;
  stagger?: number;
  once?: boolean;
}

export function SplitHeading({
  children,
  className = "",
  as: Tag = "h2",
  delay = 0,
  stagger = 0.025,
  once = true,
}: SplitHeadingProps) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once, margin: "-40px 0px" });
  const lines = children.split("\n");

  let globalIdx = 0;

  return (
    <Tag ref={ref} className={className}>
      {lines.map((line, lineIdx) => (
        <span key={lineIdx} className="block overflow-hidden">
          {line.split("").map((char) => {
            const idx = globalIdx++;
            return (
              <motion.span
                key={`${lineIdx}-${idx}`}
                initial={{ opacity: 0, y: 40, filter: "blur(8px)" }}
                animate={
                  isInView
                    ? { opacity: 1, y: 0, filter: "blur(0px)" }
                    : { opacity: 0, y: 40, filter: "blur(8px)" }
                }
                transition={{
                  delay: delay + idx * stagger,
                  duration: 0.5,
                  ease: [0.22, 1, 0.36, 1],
                }}
                className="inline-block"
                style={{ whiteSpace: char === " " ? "pre" : undefined }}
              >
                {char}
              </motion.span>
            );
          })}
        </span>
      ))}
    </Tag>
  );
}

/* ─── WordReveal ─────────────────────────────────────────── */

interface WordRevealProps {
  children: string;
  className?: string;
  as?: "h1" | "h2" | "h3" | "h4" | "p" | "span";
  delay?: number;
  once?: boolean;
}

export function WordReveal({
  children,
  className = "",
  as: Tag = "p",
  delay = 0,
  once = true,
}: WordRevealProps) {
  const ref = useRef(null);
  const isInView = useInView(ref, { once, margin: "-40px 0px" });
  const words = children.split(" ");

  return (
    <Tag ref={ref} className={className}>
      {words.map((word, i) => (
        <span key={i} className="inline-block overflow-hidden mr-[0.3em]">
          <motion.span
            className="inline-block"
            initial={{ y: "100%", opacity: 0 }}
            animate={
              isInView
                ? { y: "0%", opacity: 1 }
                : { y: "100%", opacity: 0 }
            }
            transition={{
              delay: delay + i * 0.05,
              duration: 0.55,
              ease: [0.22, 1, 0.36, 1],
            }}
          >
            {word}
          </motion.span>
        </span>
      ))}
    </Tag>
  );
}

/* ─── BlurFadeIn ─────────────────────────────────────────── */
/* Simple wrapper: fades in + de-blurs on scroll into view. */

interface BlurFadeInProps {
  children: React.ReactNode;
  className?: string;
  delay?: number;
  once?: boolean;
  direction?: "up" | "down" | "left" | "right";
}

export function BlurFadeIn({
  children,
  className = "",
  delay = 0,
  once = true,
  direction = "up",
}: BlurFadeInProps) {
  const offsets = {
    up: { y: 30 },
    down: { y: -30 },
    left: { x: 30 },
    right: { x: -30 },
  };

  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, filter: "blur(6px)", ...offsets[direction] }}
      whileInView={{ opacity: 1, filter: "blur(0px)", x: 0, y: 0 }}
      viewport={{ once, margin: "-60px" }}
      transition={{
        delay,
        duration: 0.6,
        ease: [0.22, 1, 0.36, 1],
      }}
    >
      {children}
    </motion.div>
  );
}

/* ─── CountUp ────────────────────────────────────────────── */
/* Animates a number counting up from 0 when it scrolls in. */

interface CountUpProps {
  value: number;
  className?: string;
  duration?: number;
  delay?: number;
}

export function CountUp({
  value,
  className = "",
  duration = 1.5,
  delay = 0,
}: CountUpProps) {
  const ref = useRef<HTMLSpanElement>(null);

  return (
    <motion.span
      ref={ref}
      className={className}
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true, margin: "-40px" }}
      onViewportEnter={() => {
        if (!ref.current) return;
        const end = value;
        const startTime = performance.now();
        const delayMs = delay * 1000;

        const animate = (now: number) => {
          const elapsed = now - startTime - delayMs;
          if (elapsed < 0) {
            ref.current!.textContent = "0";
            requestAnimationFrame(animate);
            return;
          }
          const progress = Math.min(elapsed / (duration * 1000), 1);
          // Ease out cubic
          const eased = 1 - Math.pow(1 - progress, 3);
          ref.current!.textContent = String(Math.round(eased * end));
          if (progress < 1) requestAnimationFrame(animate);
        };
        requestAnimationFrame(animate);
      }}
    >
      0
    </motion.span>
  );
}

/* ─── TypeWriter ─────────────────────────────────────────── */
/* Types out text character by character with a blinking cursor. */

interface TypeWriterProps {
  text: string;
  className?: string;
  speed?: number;
  delay?: number;
  cursor?: boolean;
}

export function TypeWriter({
  text,
  className = "",
  speed = 50,
  delay = 0,
  cursor = true,
}: TypeWriterProps) {
  const ref = useRef<HTMLSpanElement>(null);

  return (
    <motion.span
      ref={ref}
      className={className}
      initial={{ opacity: 0 }}
      whileInView={{ opacity: 1 }}
      viewport={{ once: true, margin: "-40px" }}
      onViewportEnter={() => {
        if (!ref.current) return;
        const el = ref.current;
        let i = 0;
        const delayMs = delay * 1000;

        setTimeout(() => {
          const interval = setInterval(() => {
            i++;
            el.textContent = text.slice(0, i) + (cursor && i < text.length ? "▌" : "");
            if (i >= text.length) {
              clearInterval(interval);
              if (cursor) {
                // Blinking cursor at end
                let visible = true;
                const blink = setInterval(() => {
                  visible = !visible;
                  el.textContent = text + (visible ? "▌" : "");
                }, 530);
                setTimeout(() => {
                  clearInterval(blink);
                  el.textContent = text;
                }, 3000);
              }
            }
          }, speed);
        }, delayMs);
      }}
    >
      &nbsp;
    </motion.span>
  );
}

/* ─── LineReveal ─────────────────────────────────────────── */
/* A decorative animated line that draws itself in. */

interface LineRevealProps {
  className?: string;
  delay?: number;
  direction?: "horizontal" | "vertical";
  color?: string;
}

export function LineReveal({
  className = "",
  delay = 0,
  direction = "horizontal",
  color = "var(--cyan)",
}: LineRevealProps) {
  const isHorizontal = direction === "horizontal";

  return (
    <motion.div
      className={className}
      style={{
        background: color,
        ...(isHorizontal
          ? { height: "1px", width: "100%" }
          : { width: "1px", height: "100%" }),
      }}
      initial={{
        scaleX: isHorizontal ? 0 : 1,
        scaleY: isHorizontal ? 1 : 0,
        opacity: 0.5,
      }}
      whileInView={{
        scaleX: 1,
        scaleY: 1,
        opacity: 0.4,
      }}
      viewport={{ once: true }}
      transition={{ delay, duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
    />
  );
}
