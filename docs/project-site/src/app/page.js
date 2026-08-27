import { Header } from '@/components/Header';
import { Hero } from '@/components/Hero';
import { WhatItDoes } from '@/components/WhatItDoes';
import { WhyItExists } from '@/components/WhyItExists';
import { Screens } from '@/components/Screens';
import { Pairing } from '@/components/Pairing';
import { Privacy } from '@/components/Privacy';
import { Footer } from '@/components/Footer';

export default function Home() {
  return (
    <>
      <Header />
      <main className="flex-1">
        <Hero />
        <Screens />
        <WhatItDoes />
        <WhyItExists />
        <Pairing />
        <Privacy />
      </main>
      <Footer />
    </>
  );
}
