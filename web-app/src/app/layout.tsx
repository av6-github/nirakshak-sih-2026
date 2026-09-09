import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'निरीक्षक AI - Enforcement Officer Command Portal',
  description:
    'Statutory Legal Metrology Packaging Surveillance, Overcharge Redressal, and Compliance Audit System',
  icons: {
    icon: [
      { url: '/nirikshak_logo.jpeg', type: 'image/jpeg' },
    ],
    shortcut: '/nirikshak_logo.jpeg',
    apple: '/nirikshak_logo.jpeg',
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/nirikshak_logo.jpeg" type="image/jpeg" />
        <link rel="shortcut icon" href="/nirikshak_logo.jpeg" type="image/jpeg" />
        <link rel="apple-touch-icon" href="/nirikshak_logo.jpeg" />
      </head>
      <body>{children}</body>
    </html>
  );
}
