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
              Circuit Weaver · Last updated: March 2026
            </p>
          </header>

          <div className="font-mono text-sm tracking-wide text-foreground/80 space-y-6 leading-relaxed">
              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  1. Introduction
                </h2>
                <p>
                  Circuit Weaver (&quot;we&quot;, &quot;our&quot;, or &quot;the app&quot;) is an educational game designed for children and learners of all ages that teaches logic gates by building circuits. This privacy policy explains how we handle information when you use the app and the website at circuitweaver.devmubarak.me.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  2. Information We Collect
                </h2>
                <p>
                  <strong className="text-foreground">Locally stored data:</strong> The app stores data locally on your device, such as your chosen architect name, age, level progress (levels completed, stars earned), and preferences. This data stays entirely on your device and is not transmitted to our servers.
                </p>
                <p className="mt-2">
                  <strong className="text-foreground">Third-party services:</strong> The app uses the following third-party services that may automatically collect certain data:
                </p>
                <ul className="list-disc list-inside mt-2 space-y-1 pl-4">
                  <li>
                    <strong className="text-foreground">Google AdMob</strong> — for displaying advertisements. AdMob may collect device identifiers (such as the Advertising ID) and basic device information for the purpose of serving ads. In our app, ads are configured as child-directed: interest-based advertising and remarketing are disabled. See{" "}
                    <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" className="text-cyan hover:underline">Google&apos;s Privacy Policy</a>.
                  </li>
                  <li>
                    <strong className="text-foreground">Firebase Analytics</strong> — for understanding how the app is used (e.g. which levels are played, app interactions, crash diagnostics). Firebase may collect device information, app usage data, and diagnostic data. See{" "}
                    <a href="https://firebase.google.com/support/privacy" target="_blank" rel="noopener noreferrer" className="text-cyan hover:underline">Firebase Privacy Information</a>.
                  </li>
                </ul>
                <p className="mt-2">
                  <strong className="text-foreground">On the website:</strong> We may collect non-personally identifying information such as browser type, language, and referring site. We do not sell your personal data.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  3. How We Use Information
                </h2>
                <p>
                  We use locally stored data to provide the game experience (e.g. resuming your progress, displaying your chosen name). Data collected by third-party services is used for displaying advertisements and for analytics to improve the app experience. Shared result images and captions are only sent through your device&apos;s share sheet to the apps you choose (e.g. social networks).
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  4. Children&apos;s Privacy (COPPA &amp; GDPR-K)
                </h2>
                <p>
                  Circuit Weaver is designed for children aged 5 and older. We take children&apos;s privacy very seriously and comply with the US Children&apos;s Online Privacy Protection Act (COPPA) and the EU General Data Protection Regulation (GDPR) provisions regarding children.
                </p>
                <ul className="list-disc list-inside mt-2 space-y-1 pl-4">
                  <li>We do <strong className="text-foreground">not</strong> knowingly collect personal information from children under 13 (or the applicable age in your jurisdiction) without verifiable parental consent.</li>
                  <li>Advertisements shown in the app are configured as <strong className="text-foreground">child-directed</strong>: interest-based advertising ($IBA$) and ad personalization are disabled.</li>
                  <li>We only use <strong className="text-foreground">Google Play certified ad networks</strong> (Google AdMob) which are approved for use in apps for children.</li>
                  <li>The app does not contain social features, chat, or user-to-user communication.</li>
                </ul>
                <p className="mt-2">
                  If you are a parent or guardian and believe your child has provided personal information to us, please contact us and we will promptly take steps to delete such information.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  5. Data Retention and Deletion
                </h2>
                <p>
                  Game data is stored locally on your device and remains until you clear the app data or uninstall the app. We do not transmit your game progress to our servers. To delete all locally stored data, you can:
                </p>
                <ul className="list-disc list-inside mt-2 space-y-1 pl-4">
                  <li>Clear app data from your device&apos;s Settings → Apps → Circuit Weaver → Storage → Clear Data</li>
                  <li>Uninstall the app</li>
                </ul>
                <p className="mt-2">
                  Data collected by third-party services (Google AdMob and Firebase Analytics) is retained according to their respective data retention policies. You can opt out of personalized advertising by adjusting your device&apos;s ad settings.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  6. Data Security
                </h2>
                <p>
                  All data transmitted between the app and third-party services (AdMob, Firebase) is encrypted in transit using industry-standard protocols (HTTPS/TLS). We take reasonable steps to protect any data we process, though no method of transmission over the Internet is 100% secure.
                </p>
              </section>

              <section>
                <h2 className="text-cyan text-base font-semibold tracking-wider mb-2 uppercase">
                  7. Changes to This Policy
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
                  For questions about this privacy policy or Circuit Weaver, you can reach us at:{" "}
                  <a
                    href="mailto:rmbabatunde123@gmail.com"
                    className="text-cyan hover:underline"
                  >
                    rmbabatunde123@gmail.com
                  </a>
                  {" "}or open an issue on our{" "}
                  <a
                    href="https://github.com/DevMubarak1/Circuit-Weaver"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-cyan hover:underline"
                  >
                    GitHub repository
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
