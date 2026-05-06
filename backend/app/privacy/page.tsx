import Link from "next/link";

export default function PrivacyPage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16 leading-relaxed">
      <Link href="/" className="text-sm text-rama-textSecondary hover:underline">
        ← Likhita Foundation
      </Link>
      <h1 className="mt-4 font-display text-4xl">Privacy</h1>
      <p className="mt-2 text-sm text-rama-textSecondary">
        Last updated: this is a v1 placeholder. The final policy will be
        reviewed by counsel before launch.
      </p>
      <div className="gold-line my-8" />

      <article className="space-y-6 text-rama-textPrimary">
        <section>
          <h2 className="font-display text-2xl">What we collect</h2>
          <p className="mt-2">
            Name, email, optional gotra and native place, phone number for
            shipping, and shipping address if you ship a koti. We collect
            keystroke cadence as an anti-cheat signature — only timing
            statistics, never the keystrokes themselves.
          </p>
        </section>
        <section>
          <h2 className="font-display text-2xl">What we never collect</h2>
          <p className="mt-2">
            Location, device contacts, screen recordings, app usage outside our
            apps, biometric identifiers.
          </p>
        </section>
        <section>
          <h2 className="font-display text-2xl">Who we share with</h2>
          <p className="mt-2">
            Stripe and Razorpay for payments, Resend for transactional email,
            Apple for App Store and StoreKit. We do not sell, rent, or
            advertise against your data.
          </p>
        </section>
        <section>
          <h2 className="font-display text-2xl">Your rights</h2>
          <p className="mt-2">
            Request export or deletion of your data at any time by emailing the
            foundation. We respond within 30 days.
          </p>
        </section>
      </article>
    </main>
  );
}
