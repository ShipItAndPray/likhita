import Link from "next/link";

export default function TermsPage() {
  return (
    <main className="mx-auto max-w-3xl px-6 py-16 leading-relaxed">
      <Link href="/" className="text-sm text-rama-textSecondary hover:underline">
        ← Likhita Foundation
      </Link>
      <h1 className="mt-4 font-display text-4xl">Terms of Service</h1>
      <p className="mt-2 text-sm text-rama-textSecondary">
        Placeholder. Final terms will be reviewed by counsel before launch.
      </p>
      <div className="gold-line my-8" />

      <article className="space-y-6 text-rama-textPrimary">
        <section>
          <h2 className="font-display text-2xl">Use of the apps</h2>
          <p className="mt-2">
            The Likhita Rama and Likhita Ram apps are provided as devotional
            tools. You agree to write entries personally; macros, paste, or
            scripted automation violate these terms and your koti may be
            invalidated.
          </p>
        </section>
        <section>
          <h2 className="font-display text-2xl">Payments and shipping</h2>
          <p className="mt-2">
            Ship-to-temple and ship-to-home services are best-effort
            quarterly batches. Estimated arrival dates are not guarantees.
            Refunds are issued for non-shipment within 12 months.
          </p>
        </section>
        <section>
          <h2 className="font-display text-2xl">Donations</h2>
          <p className="mt-2">
            Donations are non-refundable except where required by law. The
            foundation is registered as a Section 8 Co. in India and is
            applying for 501(c)(3) status in the United States.
          </p>
        </section>
      </article>
    </main>
  );
}
