import Link from "next/link";

type LedgerRow = {
  quarter: string;
  totalKotis: number;
  inrReceived: number;
  usdReceived: number;
  shipsToTemples: number;
  shipsToHomes: number;
  reportUrl: string | null;
};

// Stub fetch. Production loads from a materialized view aggregating ship_batches
// + payments per quarter. Kept small so the page renders without a DB during dev.
async function fetchLedger(): Promise<LedgerRow[]> {
  return [
    {
      quarter: "2026-Q1",
      totalKotis: 0,
      inrReceived: 0,
      usdReceived: 0,
      shipsToTemples: 0,
      shipsToHomes: 0,
      reportUrl: null,
    },
  ];
}

export default async function TransparencyPage() {
  const ledger = await fetchLedger();

  return (
    <main className="mx-auto max-w-4xl px-6 py-16">
      <header>
        <Link href="/" className="text-sm text-rama-textSecondary hover:underline">
          ← Likhita Foundation
        </Link>
        <h1 className="mt-4 font-display text-4xl">Transparency</h1>
        <p className="mt-2 text-rama-textSecondary">
          Every quarter we publish: kotis completed, money received in INR and
          USD, books printed, books shipped to temples, books shipped to homes,
          and the audited financial report.
        </p>
        <div className="gold-line my-8" />
      </header>

      <section>
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-rama-accent/40 text-left">
              <th className="py-3 pr-3 font-medium">Quarter</th>
              <th className="py-3 pr-3 font-medium">Kotis</th>
              <th className="py-3 pr-3 font-medium">INR</th>
              <th className="py-3 pr-3 font-medium">USD</th>
              <th className="py-3 pr-3 font-medium">To temples</th>
              <th className="py-3 pr-3 font-medium">To homes</th>
              <th className="py-3 pr-3 font-medium">Report</th>
            </tr>
          </thead>
          <tbody>
            {ledger.map((row) => (
              <tr key={row.quarter} className="border-b border-rama-accent/20">
                <td className="py-3 pr-3">{row.quarter}</td>
                <td className="py-3 pr-3">{row.totalKotis}</td>
                <td className="py-3 pr-3">₹{row.inrReceived.toLocaleString("en-IN")}</td>
                <td className="py-3 pr-3">${row.usdReceived.toLocaleString("en-US")}</td>
                <td className="py-3 pr-3">{row.shipsToTemples}</td>
                <td className="py-3 pr-3">{row.shipsToHomes}</td>
                <td className="py-3 pr-3">
                  {row.reportUrl ? (
                    <Link href={row.reportUrl} className="text-rama-brand underline">
                      PDF
                    </Link>
                  ) : (
                    <span className="text-rama-textSecondary">pending</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="mt-16 rounded-lg bg-rama-surfaceAlt p-6 text-sm text-rama-textSecondary">
        <p>
          Audited annually by a chartered firm in Hyderabad. The Section 8 Co.
          (India) and 501(c)(3) (US) annual filings are linked from this page
          once published.
        </p>
      </section>
    </main>
  );
}
