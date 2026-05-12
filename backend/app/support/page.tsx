import Link from "next/link";

export default function SupportPage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16 leading-relaxed">
      <Link
        href="/"
        className="text-sm text-rama-textSecondary hover:underline"
      >
        ← Likhita Foundation
      </Link>
      <h1 className="mt-4 font-display text-4xl">Support</h1>
      <p className="mt-2 text-sm text-rama-textSecondary">
        For help with the Likhita Rama or Likhita Ram app.
      </p>
      <div className="gold-line my-8" />

      <h2 className="mt-8 font-display text-2xl">Contact</h2>
      <p className="mt-2">
        Reach the Likhita Foundation via the contact form on the{" "}
        <Link href="/" className="underline">Foundation landing page</Link>.
        Include your question, the app you are using (Likhita Rama or Likhita
        Ram), and your device model + iOS version. We reply within two
        business days.
      </p>

      <h2 className="mt-10 font-display text-2xl">Frequently asked</h2>

      <h3 className="mt-6 font-medium">My count went down after restarting the app</h3>
      <p className="mt-2">
        This should not happen. Likhita stores every committed mantra on disk
        before flushing to the server, and the server is the source of truth.
        If you see a regression, send us the time it occurred, the app, and
        the device — we keep server-side audit logs and will reconcile.
      </p>

      <h3 className="mt-6 font-medium">Why is my book taking so long to be printed and shipped?</h3>
      <p className="mt-2">
        Each completed koti is professionally printed and physically deposited
        at the temple it&apos;s bound for (Bhadrachalam for Likhita Rama, Ram Naam
        Bank Varanasi for Likhita Ram). Print + ship is currently 8–12 weeks
        from the moment your final mantra is server-confirmed. You receive a
        receipt photo when it arrives at the temple.
      </p>

      <h3 className="mt-6 font-medium">Where does my money go?</h3>
      <p className="mt-2">
        Cost-recovery only. Printing + temple courier + payment processing,
        nothing more. Full audited line items at{" "}
        <Link href="/transparency" className="underline">/transparency</Link>.
      </p>

      <h3 className="mt-6 font-medium">Can I write more than one mantra at a time?</h3>
      <p className="mt-2">
        No. The practice is one-at-a-time by design. The app rejects batches
        that look macro-typed (zero variance, sub-30ms intervals).
      </p>

      <h3 className="mt-6 font-medium">Can I delete my data?</h3>
      <p className="mt-2">
        Personal kotis can be deleted (which removes your name and any
        identifying metadata). Entries appended to the Sangha (shared) koti
        are append-only by design and cannot be removed — but they are
        attributed to a rotating anonymous device ID, never your name.
      </p>

      <h2 className="mt-10 font-display text-2xl">Reporting a bug</h2>
      <p className="mt-2">
        Use the contact form on the{" "}
        <Link href="/" className="underline">Foundation landing page</Link>
        {" "}with a screenshot, the app + version (from Settings → About), and
        the steps that produced it. We treat data-loss bugs as P0 and respond
        within four hours.
      </p>
    </main>
  );
}
