import type { Metadata } from "next";
import { Space_Grotesk, JetBrains_Mono } from "next/font/google";
import "./globals.css";

const spaceGrotesk = Space_Grotesk({
  variable: "--font-space",
  subsets: ["latin"],
  weight: ["300", "400", "500", "600", "700"],
});

const jetbrainsMono = JetBrains_Mono({
  variable: "--font-jetbrains",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

export const metadata: Metadata = {
  title: "Circuit Weaver — Learn Logic Gates by Building Circuits",
  description:
    "A digital logic puzzle game where you learn how computers actually work by wiring real logic gates. 20 levels, 7 gate types, zero boring lectures.",
  keywords: [
    "logic gates",
    "circuit puzzle",
    "educational game",
    "digital logic",
    "AND OR NOT XOR",
    "computer science",
    "Godot",
  ],
  icons: {
    icon: [
      { url: "/favicon.ico", sizes: "32x32" },
      { url: "/favicon.svg", type: "image/svg+xml" },
    ],
  },
  openGraph: {
    title: "Circuit Weaver",
    description: "Learn logic gates by building circuits. 20 puzzles. Zero boring lectures.",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark">
      <body
        className={`${spaceGrotesk.variable} ${jetbrainsMono.variable} antialiased bg-midnight text-foreground`}
      >
        {children}
      </body>
    </html>
  );
}
