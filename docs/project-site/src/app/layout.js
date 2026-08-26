import './globals.css';
import { ThemeProvider } from '@/components/ThemeProvider';

export const metadata = {
  title: 'webOS Dev Mode Manager',
  description:
    'A mobile-first Android app for LG webOS TVs in Developer Mode. Pair a TV from a phone, install homebrew apps on it, and keep track of how long the Developer Mode session has left.',
  icons: { icon: '/icon.svg' },
  openGraph: {
    title: 'webOS Dev Mode Manager',
    description:
      'Manage an LG webOS TV in Developer Mode from a phone. Pair, install homebrew apps, and watch the session clock.',
    type: 'website',
  },
};

export default function RootLayout({ children }) {
  return (
    // suppressHydrationWarning because next-themes writes the theme class
    // onto <html> in a blocking script before React hydrates, which is
    // the whole reason there is no flash of the wrong theme on load.
    <html lang="en" className="antialiased" suppressHydrationWarning>
      <body className="min-h-screen flex flex-col">
        <ThemeProvider
          attribute="class"
          defaultTheme="dark"
          enableSystem
          // The instant swap. Without it every themed colour animates at
          // its own pace and the page appears to melt between states
          // rather than change.
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
