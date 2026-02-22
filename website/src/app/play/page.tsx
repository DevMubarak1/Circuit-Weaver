"use client";

import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";

export default function PlayPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [mounted, setMounted] = useState(false);
  const [isPortrait, setIsPortrait] = useState(false);
  const iframeRef = useRef<HTMLIFrameElement>(null);

  const dismissLoader = useCallback(() => setIsLoading(false), []);

  useEffect(() => {
    setMounted(true);
    const t = setTimeout(dismissLoader, 4000);
    return () => clearTimeout(t);
  }, [dismissLoader]);

  // Detect portrait on mobile
  useEffect(() => {
    const check = () => {
      setIsPortrait(window.innerWidth < 768 && window.innerHeight > window.innerWidth);
    };
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);

  const toggleFullscreen = () => {
    const container = document.getElementById("game-container");
    if (!container) return;

    if (!document.fullscreenElement) {
      container.requestFullscreen().then(() => setIsFullscreen(true));
    } else {
      document.exitFullscreen().then(() => setIsFullscreen(false));
    }
  };

  return (
    <main className="h-[100svh] bg-[#0B0E14] flex flex-col overflow-hidden">
      {/* Minimal nav bar */}
      <div
        className={`glass-panel !rounded-none border-x-0 border-t-0 px-4 sm:px-6 py-2 sm:py-3 flex items-center justify-between shrink-0 transition-opacity duration-500 ${mounted ? "opacity-100" : "opacity-0"}`}
      >
        <Link href="/" className="flex items-center gap-2 group">
          <span className="font-mono text-sm sm:text-base font-bold tracking-wider">
            <span className="text-cyan group-hover:text-pink transition-colors duration-300">CW</span>
            <span className="text-foreground/40 hidden sm:inline ml-1.5">Circuit Weaver</span>
          </span>
        </Link>

        <div className="flex items-center gap-2 sm:gap-4">
          <button
            onClick={toggleFullscreen}
            className="hidden sm:inline-flex px-4 py-2 font-mono text-xs tracking-wider border border-foreground/20 text-foreground/50 rounded-lg hover:border-cyan/40 hover:text-cyan transition-all duration-300"
          >
            {isFullscreen ? "EXIT FULLSCREEN" : "FULLSCREEN"}
          </button>
          <button
            onClick={toggleFullscreen}
            className="sm:hidden p-2 text-foreground/50 hover:text-cyan transition-colors"
            aria-label="Toggle fullscreen"
          >
            <svg viewBox="0 0 20 20" className="w-5 h-5" fill="none" stroke="currentColor" strokeWidth="1.5">
              {isFullscreen ? (
                <path d="M3 12h4v4M17 8h-4V4M3 8h4V4M17 12h-4v4" strokeLinecap="round" strokeLinejoin="round" />
              ) : (
                <path d="M3 7V3h4M17 7V3h-4M3 13v4h4M17 13v4h-4" strokeLinecap="round" strokeLinejoin="round" />
              )}
            </svg>
          </button>
          <Link
            href="/"
            className="px-3 sm:px-4 py-2 font-mono text-xs tracking-wider text-foreground/30 hover:text-foreground/60 transition-colors"
          >
            BACK
          </Link>
        </div>
      </div>

      {/* Game container — fills all remaining space, no aspect ratio lock */}
      <div className="flex-1 min-h-0">
        <div
          id="game-container"
          className={`relative w-full h-full overflow-hidden transition-opacity duration-500 ${mounted ? "opacity-100" : "opacity-0"}`}
          style={{ backgroundColor: "#0B0E14" }}
        >
          {/* Portrait rotation prompt */}
          {isPortrait && (
            <div className="absolute inset-0 z-30 flex flex-col items-center justify-center gap-5 bg-[#0B0E14]/95">
              <svg viewBox="0 0 64 64" className="w-14 h-14 text-cyan/50 animate-[rotate-hint_2.5s_ease-in-out_infinite]">
                <rect x="16" y="4" width="32" height="56" rx="4" fill="none" stroke="currentColor" strokeWidth="2.5" />
                <circle cx="32" cy="52" r="2.5" fill="currentColor" opacity="0.4" />
                <rect x="26" y="6" width="12" height="3" rx="1.5" fill="currentColor" opacity="0.3" />
              </svg>
              <p className="font-mono text-xs tracking-[0.25em] text-cyan/60">ROTATE YOUR DEVICE</p>
              <p className="font-mono text-[10px] text-foreground/20 max-w-[200px] text-center leading-relaxed">
                Circuit Weaver plays best in landscape
              </p>
            </div>
          )}

          {/* Loading overlay */}
          {isLoading && (
            <div
              onClick={dismissLoader}
              className={`absolute inset-0 z-20 flex flex-col items-center justify-center gap-4 sm:gap-6 bg-[#0B0E14] cursor-pointer transition-opacity duration-400 ${isLoading ? "opacity-100" : "opacity-0 pointer-events-none"}`}
            >
              <div className="relative w-14 h-14 sm:w-20 sm:h-20">
                <svg viewBox="0 0 100 100" className="w-full h-full animate-spin" style={{ animationDuration: "3s" }}>
                  <circle cx="50" cy="50" r="40" fill="none" stroke="#1F2430" strokeWidth="4" />
                  <circle cx="50" cy="50" r="40" fill="none" stroke="#00F5FF" strokeWidth="4" strokeLinecap="round" strokeDasharray="80 170" />
                </svg>
                <div className="absolute inset-0 flex items-center justify-center">
                  <span className="font-mono text-xs font-bold text-cyan/60">CW</span>
                </div>
              </div>
              <div className="text-center px-4">
                <p className="font-mono text-[11px] sm:text-sm tracking-widest text-cyan/80 mb-1">
                  LOADING...
                </p>
              </div>
            </div>
          )}

          <iframe
            ref={iframeRef}
            src="/game/index.html"
            className="w-full h-full border-0 block"
            allow="autoplay; fullscreen; gamepad"
            loading="eager"
            onLoad={dismissLoader}
            title="Circuit Weaver Game"
          />
        </div>
      </div>
    </main>
  );
}
