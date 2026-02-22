import Navbar from "@/components/Navbar";
import HeroSection from "@/components/HeroSection";
import FeaturesSection from "@/components/FeaturesSection";
import GatesSection from "@/components/GatesSection";
import ChaptersSection from "@/components/ChaptersSection";
import CTASection from "@/components/CTASection";
import Footer from "@/components/Footer";

export default function Home() {
  return (
    <main className="relative min-h-screen bg-midnight circuit-grid">
      <Navbar />
      <HeroSection />
      <FeaturesSection />
      <GatesSection />
      <ChaptersSection />
      <CTASection />
      <Footer />
    </main>
  );
}
