import Link from "next/link";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export const metadata = {
  title: "Privacy Policy — Circuit Weaver",
  description: "Privacy policy for Circuit Weaver. How we collect, use, and protect your data.",
};

export default function PrivacyPolicyPage() {
  return (
    <main className="relative min-h-screen bg-midnight circuit-grid">
      <Navbar />
      <div className="pt-24 sm:pt-28 pb-16 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <header className="mb-8">
            <Link
              href="/"
              className="inline-flex items-center gap-2 font-mono text-xs tracking-wider text-foreground/50 hover:text-cyan transition-colors mb-6"
            >
              <span>←</span> Back
            </Link>
            <h1 className="font-mono text-2xl sm:text-3xl font-bold tracking-wider text-cyan glow-text-cyan">
              PRIVACY POLICY
            </h1>
            <p className="font-mono text-xs tracking-wider text-foreground/40 mt-2">
              Circuit Weaver · Last updated: February 2025
            </p>
          </header>

          <div className="font-mono text-sm tracking-wide text-foreground/80 space-y-6 leading-relaxed">
              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  1. Introduction
                </h2>
                <p>
                  Circuit Weaver (&quot;we&quot;, &quot;our&quot;, or &quot;the app&quot;) is an educational game that teaches logic gates by building circuits. This privacy policy explains how we handle information when you use the app and the website at circuitweaver.devmubarak.me.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  2. Information we collect
                </h2>
                <p>
                  <strong className="text-foreground">In the app:</strong> We may store data locally on your device, such as your chosen architect name, age, progress (levels completed, stars), and preferences. This data stays on your device unless you use features that share it (e.g. sharing a result image).
                </p>
                <p>
                  <strong className="text-foreground">On the website:</strong> We may collect non-personally identifying information such as browser type, language, and referring site. We do not sell your personal data.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  3. How we use information
                </h2>
                <p>
                  We use locally stored data to provide the game experience (e.g. resuming progress, displaying your name). If the app uses third-party services (e.g. analytics or ads), those services have their own privacy policies. Shared result images and captions are only sent through your device’s share sheet to the apps you choose (e.g. social networks).
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  4. Third-party services
                </h2>
                <p>
                  The app or website may use third-party services (e.g. for analytics or advertising). Their use of data is governed by their respective privacy policies. We encourage you to review those policies.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  5. Data retention and security
                </h2>
                <p>
                  Data stored on your device remains until you clear app data or uninstall. We do not transmit your progress to our servers unless a specific feature (e.g. cloud sync) is introduced and described elsewhere. We take reasonable steps to protect any data we process.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  6. Children
                </h2>
                <p>
                  Circuit Weaver is aimed at a general audience. We do not knowingly collect personal information from children without parental consent. If you believe we have collected such information, please contact us and we will take steps to delete it.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  7. Changes to this policy
                </h2>
                <p>
                  We may update this privacy policy from time to time. The &quot;Last updated&quot; date at the top will be revised when changes are made. Continued use of the app or website after changes constitutes acceptance of the updated policy.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  8. Contact
                </h2>
                <p>
                  For questions about this privacy policy or Circuit Weaver, you can open an issue or contact the maintainers via the project repository:{" "}
                  <a
                    href="https://github.com/DevMubarak1/Circuit-Weaver"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-cyan hover:underline"
                  >
                    GitHub — Circuit-Weaver
                  </a>
                  .
                </p>
              </section>
          </div>

          <footer className="mt-10 pt-6 border-t border-foreground/10">
            <Link
              href="/"
              className="inline-flex items-center gap-2 font-mono text-xs tracking-wider text-cyan hover:text-pink transition-colors"
            >
              <span>←</span> Back to Circuit Weaver
            </Link>
          </footer>
        </div>
      </div>
      <Footer />
    </main>
  );
}
