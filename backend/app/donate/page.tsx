import Link from "next/link";

const PRESET_USD = [25, 51, 108, 251];
const PRESET_INR = [501, 1100, 2100, 5100];

export default function DonatePage() {
  return (
    <main className="mx-auto max-w-2xl px-6 py-16">
      <Link href="/" className="text-sm text-rama-textSecondary hover:underline">
        ← Likhita Foundation
      </Link>
      <h1 className="mt-4 font-display text-4xl">Support the foundation</h1>
      <p className="mt-3 text-rama-textSecondary">
        Every contribution funds book printing, temple shipping, and audit
        compliance. Donations are tax-deductible in India (Section 8 Co.) and
        the United States (501(c)(3) pending).
      </p>
      <div className="gold-line my-8" />

      <section className="grid gap-6 sm:grid-cols-2">
        <form
          action="/api/v1/donations/inr"
          method="post"
          className="rounded-lg border border-rama-accent/40 bg-rama-surfaceAlt p-6"
        >
          <h2 className="font-display text-xl">India (INR)</h2>
          <p className="mt-1 text-xs text-rama-textSecondary">via Razorpay</p>
          <div className="mt-4 grid grid-cols-2 gap-2">
            {PRESET_INR.map((amt) => (
              <button
                key={amt}
                type="submit"
                name="amountInr"
                value={amt}
                className="rounded border border-rama-accent/60 px-3 py-2 text-sm hover:bg-rama-accent/20"
              >
                ₹{amt.toLocaleString("en-IN")}
              </button>
            ))}
          </div>
        </form>

        <form
          action="/api/v1/donations/usd"
          method="post"
          className="rounded-lg border border-rama-accent/40 bg-rama-surfaceAlt p-6"
        >
          <h2 className="font-display text-xl">United States (USD)</h2>
          <p className="mt-1 text-xs text-rama-textSecondary">via Stripe</p>
          <div className="mt-4 grid grid-cols-2 gap-2">
            {PRESET_USD.map((amt) => (
              <button
                key={amt}
                type="submit"
                name="amountUsd"
                value={amt}
                className="rounded border border-rama-accent/60 px-3 py-2 text-sm hover:bg-rama-accent/20"
              >
                ${amt}
              </button>
            ))}
          </div>
        </form>
      </section>

      <p className="mt-12 text-xs text-rama-textSecondary">
        Receipts are emailed within 24 hours. For corporate matching, wire
        transfers, or stock gifts, contact the foundation directly.
      </p>
    </main>
  );
}
