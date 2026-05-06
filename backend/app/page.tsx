import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-20">
      <header className="text-center">
        <p className="text-sm uppercase tracking-widest text-rama-textSecondary">
          Likhita Foundation
        </p>
        <h1 className="mt-4 font-display text-5xl text-rama-textPrimary">
          One koti at a time
        </h1>
        <div className="gold-line my-8" />
        <p className="text-lg leading-relaxed text-rama-textSecondary">
          A non-profit dedicated to preserving the practice of Rama-naam likhita
          across India and the diaspora. We build tools that respect tradition,
          ship books to temples, and publish every rupee on this site.
        </p>
      </header>

      <section className="mt-16 grid gap-6 sm:grid-cols-2">
        <Link
          href="https://likhitarama.org"
          className="rounded-lg border border-rama-accent/40 bg-rama-surfaceAlt p-8 transition hover:border-rama-accent"
        >
          <h2 className="font-display text-2xl">Likhita Rama</h2>
          <p className="mt-2 text-sm text-rama-textSecondary">
            Telugu-tradition Rama Koti — Bhadrachalam aesthetic, Tiro Telugu
            script, completion shipped to Bhadrachalam temple.
          </p>
        </Link>
        <Link
          href="https://likhitaram.org"
          className="rounded-lg border border-rama-accent/40 bg-rama-surfaceAlt p-8 transition hover:border-rama-accent"
        >
          <h2 className="font-display text-2xl">Likhita Ram</h2>
          <p className="mt-2 text-sm text-rama-textSecondary">
            Hindi-tradition Ram Naam Lekhan — Banaras pothi aesthetic, Devanagari
            script, completion shipped to the Ram Naam Bank or Ayodhya.
          </p>
        </Link>
      </section>

      <section className="mt-16 text-center">
        <Link
          href="/transparency"
          className="text-rama-brand underline-offset-4 hover:underline"
        >
          See our transparency portal
        </Link>
        <span className="mx-3 text-rama-textSecondary">·</span>
        <Link
          href="/donate"
          className="text-rama-brand underline-offset-4 hover:underline"
        >
          Donate
        </Link>
      </section>

      <footer className="mt-24 border-t border-rama-accent/30 pt-6 text-center text-xs text-rama-textSecondary">
        <Link href="/privacy" className="hover:underline">
          Privacy
        </Link>
        <span className="mx-3">·</span>
        <Link href="/terms" className="hover:underline">
          Terms
        </Link>
      </footer>
    </main>
  );
}
