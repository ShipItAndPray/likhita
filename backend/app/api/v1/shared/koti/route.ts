import { type NextRequest, NextResponse } from "next/server";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError } from "@/lib/http";

export const runtime = "nodejs";

// The Sangha — append-only foundation koti. Read endpoint is public (no
// auth required) so the Threshold screen can render the live counter
// before a user has even signed in.
//
// v1: returns sample static data sourced from design v2 shared-data.jsx.
// v2 will replace with a SELECT from a dedicated shared_kotis row.

const SAMPLE = {
  name: "The Foundation Koti",
  nameLocal: "సర్వజన రామ కోటి",
  target: 10_000_000,
  count: 7_842_316,
  uniqueWriters: 14_627,
  countriesActive: 47,
  startedOn: "Sankranti · Jan 14, 2026",
  custodian: "Likhita Foundation",
  destination: "Sri Sita Ramachandra Swamy Temple, Bhadrachalam",
  estimatedShipDate: "Vaikuntha Ekadashi · Dec 31, 2026",
} as const;

const RECENT_WRITERS = [
  { name: "Lakshmi P.", place: "Hyderabad",     count: 412,  ago: "2s" },
  { name: "Anonymous",  place: "Toronto",       count: 108,  ago: "14s" },
  { name: "Ravi K.",    place: "Bengaluru",     count: 51,   ago: "38s" },
  { name: "Sita N.",    place: "New Jersey",    count: 216,  ago: "1m" },
  { name: "Anonymous",  place: "Mumbai",        count: 1008, ago: "2m" },
  { name: "Hemanth R.", place: "Vijayawada",    count: 108,  ago: "3m" },
  { name: "Padmaja S.", place: "Chennai",       count: 27,   ago: "4m" },
  { name: "Anonymous",  place: "Singapore",     count: 324,  ago: "6m" },
  { name: "Krishna M.", place: "Bhadrachalam",  count: 1116, ago: "7m" },
  { name: "Vidya T.",   place: "London",        count: 108,  ago: "9m" },
  { name: "Surya P.",   place: "Tirupati",      count: 216,  ago: "11m" },
  { name: "Anonymous",  place: "San Francisco", count: 51,   ago: "13m" },
] as const;

const TOP_WRITERS = [
  { name: "A devotee · Bhadrachalam",  count: 41_080, joined: "Jan 14" },
  { name: "Lakshmi P. · Hyderabad",    count: 31_752, joined: "Jan 14" },
  { name: "Krishna M. · Bhadrachalam", count: 28_116, joined: "Jan 18" },
  { name: "Anonymous · Toronto",       count: 22_500, joined: "Jan 22" },
  { name: "Padmaja S. · Chennai",      count: 18_900, joined: "Feb 02" },
  { name: "Hemanth R. · Vijayawada",   count: 14_580, joined: "Feb 11" },
] as const;

const COUNTRIES = [
  { country: "India",          count: 6_320_414 },
  { country: "United States",  count:   812_430 },
  { country: "Canada",         count:   214_600 },
  { country: "Singapore",      count:   118_200 },
  { country: "United Kingdom", count:    97_812 },
  { country: "Australia",      count:    62_080 },
  { country: "UAE",            count:    58_900 },
  { country: "+ 40 others",    count:   157_880 },
] as const;

export async function GET(req: NextRequest): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    return NextResponse.json({
      koti: SAMPLE,
      recentWriters: RECENT_WRITERS,
      topWriters: TOP_WRITERS,
      countries: COUNTRIES,
    });
  } catch (err) {
    return handleError(err);
  }
}
