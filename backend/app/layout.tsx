import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Likhita Foundation",
  description:
    "A non-profit foundation supporting traditional Rama-naam practice through technology.",
  metadataBase: new URL("https://likhita.org"),
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-rama-surface text-rama-textPrimary antialiased">
        {children}
      </body>
    </html>
  );
}
