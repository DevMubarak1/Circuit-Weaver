import Link from "next/link";

export default function Footer() {
  return (
    <footer className="border-t border-foreground/[0.04] py-8 sm:py-10 px-4 sm:px-6">
      <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
        <span className="font-mono text-xs tracking-wider text-foreground/20">
          Circuit Weaver
        </span>

        <div className="flex items-center gap-5">
          <Link
            href="https://github.com/DevMubarak1/Circuit-Weaver"
            target="_blank"
            className="font-mono text-[10px] tracking-[0.2em] text-foreground/15 hover:text-foreground/40 transition-colors uppercase flex items-center gap-1.5"
          >
            <svg className="w-3.5 h-3.5" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23a11.509 11.509 0 0 1 3.004-.404c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z"/></svg>GitHub
          </Link>
          <Link
            href="https://play.google.com/store/apps/details?id=com.circuitweaver.app"
            target="_blank"
            rel="noopener noreferrer"
            className="font-mono text-[10px] tracking-[0.2em] text-foreground/15 hover:text-foreground/40 transition-colors uppercase flex items-center gap-1.5"
          >
            <svg className="w-3 h-3" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>Play
          </Link>
          <Link
            href="/privacy"
            className="font-mono text-[10px] tracking-[0.2em] text-foreground/15 hover:text-foreground/40 transition-colors uppercase"
          >
            Privacy Policy
          </Link>
          <span className="font-mono text-[10px] tracking-[0.2em] text-foreground/10 uppercase">
            MIT
          </span>
        </div>

        <span className="font-mono text-[10px] tracking-wider text-foreground/10">
          Godot 4.5 + Next.js
        </span>
      </div>
    </footer>
  );
}
