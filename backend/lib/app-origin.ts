import { APP_ORIGINS, type AppOrigin } from "@/db/schema";

// The iOS apps send this header on every API call. The header values use
// dashes (per spec §19) while the DB persists snake_case — translate here.
const HEADER_TO_DB: Record<string, AppOrigin> = {
  "likhita-rama": "rama_koti",
  "likhita-ram": "ram_naam_lekhan",
  "rama-koti": "rama_koti",
  "ram-naam-lekhan": "ram_naam_lekhan",
};

export class AppOriginError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AppOriginError";
  }
}

export function readAppOrigin(headers: Headers): AppOrigin {
  const raw = headers.get("X-App-Origin")?.trim().toLowerCase();
  if (!raw) {
    throw new AppOriginError("Missing X-App-Origin header");
  }
  const mapped = HEADER_TO_DB[raw];
  if (!mapped || !APP_ORIGINS.includes(mapped)) {
    throw new AppOriginError(`Invalid X-App-Origin: ${raw}`);
  }
  return mapped;
}
