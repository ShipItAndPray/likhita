import type { AppOrigin } from "@/db/schema";

export type Theme = {
  key: string;
  name: string;
  appOrigin: AppOrigin | "both";
  free: boolean;
  priceInrPaise: number;
  priceUsdCents: number;
  coverArtUrl: string;
};

// Theme catalog is intentionally code-resident in v1: small set, rarely changes,
// and we want it included in the bundle for the marketing pages without a DB
// round-trip. When the catalog grows past ~25 entries, move to DB-backed.
export const THEMES: ReadonlyArray<Theme> = [
  {
    key: "bhadrachalam_classic",
    name: "Bhadrachalam Classic",
    appOrigin: "rama_koti",
    free: true,
    priceInrPaise: 0,
    priceUsdCents: 0,
    coverArtUrl: "/themes/bhadrachalam_classic.png",
  },
  {
    key: "palmleaf_telugu",
    name: "Palmleaf Telugu",
    appOrigin: "rama_koti",
    free: false,
    priceInrPaise: 19900,
    priceUsdCents: 299,
    coverArtUrl: "/themes/palmleaf_telugu.png",
  },
  {
    key: "banaras_pothi",
    name: "Banaras Pothi",
    appOrigin: "ram_naam_lekhan",
    free: true,
    priceInrPaise: 0,
    priceUsdCents: 0,
    coverArtUrl: "/themes/banaras_pothi.png",
  },
  {
    key: "ayodhya_gold",
    name: "Ayodhya Gold",
    appOrigin: "ram_naam_lekhan",
    free: false,
    priceInrPaise: 49900,
    priceUsdCents: 599,
    coverArtUrl: "/themes/ayodhya_gold.png",
  },
];

export function listThemesFor(origin: AppOrigin): Theme[] {
  return THEMES.filter((t) => t.appOrigin === origin || t.appOrigin === "both");
}

export function findTheme(key: string): Theme | undefined {
  return THEMES.find((t) => t.key === key);
}
