import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Sinapsi · Recepção",
  description: "Organização da recepção da clínica-escola SINAPSI.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR">
      <body className="antialiased">{children}</body>
    </html>
  );
}
