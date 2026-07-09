import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "BrickBack — Bring LEGO sets back from a pile of bricks",
  description:
    "BrickBack helps you rebuild complete LEGO sets from mixed or second-hand collections: pick a set, count the parts you have, verify completion, and export what's missing.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
