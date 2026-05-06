// Admin ops dashboard. In production this is gated by Clerk + an org-role
// check; for the v1 stub we simply show the layout so designers can iterate.

import Link from "next/link";

export default function AdminPage() {
  return (
    <main className="mx-auto max-w-5xl px-6 py-12">
      <header className="flex items-baseline justify-between">
        <div>
          <Link href="/" className="text-sm text-rama-textSecondary hover:underline">
            ← Foundation
          </Link>
          <h1 className="mt-2 font-display text-3xl">Ops Dashboard</h1>
        </div>
        <span className="text-xs uppercase tracking-widest text-rama-textSecondary">
          Clerk-protected
        </span>
      </header>
      <div className="gold-line my-6" />

      <section className="grid gap-4 sm:grid-cols-3">
        <Card label="Pending batches" value="—" />
        <Card label="In transit" value="—" />
        <Card label="Awaiting photo" value="—" />
      </section>

      <section className="mt-10">
        <h2 className="font-display text-xl">Active ship batches</h2>
        <p className="mt-2 text-sm text-rama-textSecondary">
          (stubbed) — production loads from <code>ship_batches</code> joined
          with <code>koti_ship_batches</code>.
        </p>
      </section>
    </main>
  );
}

function Card({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-rama-accent/40 bg-rama-surfaceAlt p-6">
      <p className="text-xs uppercase tracking-widest text-rama-textSecondary">{label}</p>
      <p className="mt-2 font-display text-3xl">{value}</p>
    </div>
  );
}
