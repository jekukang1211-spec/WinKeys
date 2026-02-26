import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "WinKeys — Windows Keyboard Shortcuts on Mac",
  description:
    "Use your familiar Windows keyboard shortcuts on Mac. Lightweight, no Karabiner needed. Free beta.",
  keywords: [
    "WinKeys",
    "Mac",
    "Windows shortcuts",
    "keyboard remapping",
    "macOS",
    "Karabiner alternative",
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={inter.className}>
      <body className="bg-white text-gray-900 antialiased">{children}</body>
    </html>
  );
}
