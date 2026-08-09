import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "TüskeAI - moduláris helyi AI rendszer",
  description: "TüskeAI bemutatkozó oldal vállalati és lakossági AI modulokhoz.",
  icons: {
    icon: "/assets/tuske-monogram.png",
    shortcut: "/assets/tuske-monogram.png",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="hu">
      <body>{children}</body>
    </html>
  );
}
